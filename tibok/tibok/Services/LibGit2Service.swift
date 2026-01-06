//
//  LibGit2Service.swift
//  tibok
//
//  Native git operations using libgit2 (sandbox-compatible).
//  This service provides the same API as GitService but uses libgit2 C bindings
//  instead of Process() calls to /usr/bin/git, making it work in App Sandbox.
//

import Foundation
import Clibgit2

// MARK: - LibGit2 Error

struct LibGit2Error: Error, LocalizedError {
    let code: Int32
    let message: String

    var errorDescription: String? { message }

    static func lastError() -> LibGit2Error {
        let error = git_error_last()
        let message = error?.pointee.message.map { String(cString: $0) } ?? "Unknown libgit2 error"
        let code = error?.pointee.klass ?? -1
        return LibGit2Error(code: code, message: message)
    }

    static func check(_ result: Int32, operation: String) throws {
        guard result >= 0 else {
            let error = lastError()
            throw LibGit2Error(code: result, message: "\(operation): \(error.message)")
        }
    }

    /// Returns a user-friendly error message for common git errors
    static func userFriendlyMessage(for errorMessage: String) -> String {
        let lowercased = errorMessage.lowercased()

        // Authentication errors
        if lowercased.contains("authentication") || lowercased.contains("credentials") {
            return "Authentication failed. Check your SSH keys are added to ssh-agent."
        }

        // Permission errors
        if lowercased.contains("permission denied") || lowercased.contains("publickey") {
            return "Permission denied. Ensure your SSH key is configured correctly."
        }

        // Network errors
        if lowercased.contains("failed to connect") || lowercased.contains("network") {
            return "Network error. Check your internet connection."
        }

        // Remote not found
        if lowercased.contains("remote") && lowercased.contains("not found") {
            return "Remote 'origin' not found. Configure a remote first."
        }

        // Default: return the original message
        return errorMessage
    }
}

// MARK: - LibGit2 Repository Wrapper

/// RAII wrapper for git_repository pointer
class LibGit2Repository {
    private var repo: OpaquePointer?

    var pointer: OpaquePointer? { repo }
    var isValid: Bool { repo != nil }

    init(at path: String) throws {
        var repoPtr: OpaquePointer?
        let result = git_repository_open(&repoPtr, path)
        try LibGit2Error.check(result, operation: "Open repository")
        self.repo = repoPtr
    }

    deinit {
        if let repo = repo {
            git_repository_free(repo)
        }
    }

    var workdir: URL? {
        guard let repo = repo,
              let path = git_repository_workdir(repo) else { return nil }
        return URL(fileURLWithPath: String(cString: path))
    }
}

// MARK: - LibGit2 Service

@MainActor
class LibGit2Service: ObservableObject {
    static let shared = LibGit2Service()

    private var isInitialized = false

    private init() {
        initializeLibGit2()
    }

    deinit {
        // Note: Can't call MainActor-isolated method from deinit
        // libgit2 will be cleaned up when app terminates
        if isInitialized {
            git_libgit2_shutdown()
        }
    }

    private func initializeLibGit2() {
        guard !isInitialized else { return }
        git_libgit2_init()
        isInitialized = true
        print("✅ [LibGit2Service] libgit2 initialized")
    }

    private func shutdownLibGit2() {
        guard isInitialized else { return }
        git_libgit2_shutdown()
        isInitialized = false
        print("🔴 [LibGit2Service] libgit2 shutdown")
    }

    // MARK: - Repository Detection

    /// Check if directory is inside a git repository
    func isGitRepository(at url: URL) -> Bool {
        return getRepositoryRoot(for: url) != nil
    }

    /// Get the root directory of the git repository containing the given path
    func getRepositoryRoot(for url: URL) -> URL? {
        print("🔍 [LibGit2Service] Detecting git repo in: \(url.path)")

        var buffer = git_buf()
        let result = git_repository_discover(&buffer, url.path, 0, nil)

        defer {
            git_buf_dispose(&buffer)
        }

        guard result == 0, let ptr = buffer.ptr else {
            print("❌ [LibGit2Service] No git repository found")
            return nil
        }

        // git_repository_discover returns path to .git directory
        let gitDirPath = String(cString: ptr)
        let repoRoot = URL(fileURLWithPath: gitDirPath)
            .deletingLastPathComponent() // Remove .git

        print("✅ [LibGit2Service] Git repo found: \(repoRoot.path)")
        return repoRoot
    }

    // MARK: - Branch Operations

    /// Get the current branch name
    func getCurrentBranch(for repoURL: URL) -> String? {
        do {
            let repo = try LibGit2Repository(at: repoURL.path)
            guard let repoPtr = repo.pointer else { return nil }

            var headRef: OpaquePointer?
            let result = git_repository_head(&headRef, repoPtr)
            guard result == 0, let head = headRef else { return nil }
            defer { git_reference_free(head) }

            // Check if we're on a branch (not detached HEAD)
            guard git_reference_is_branch(head) != 0 else { return nil }

            guard let branchName = git_reference_shorthand(head) else { return nil }
            return String(cString: branchName)
        } catch {
            print("❌ [LibGit2Service] getCurrentBranch error: \(error)")
            return nil
        }
    }

    /// Get list of all local branches
    func getBranches(for repoURL: URL) -> [String] {
        do {
            let repo = try LibGit2Repository(at: repoURL.path)
            guard let repoPtr = repo.pointer else { return [] }

            var branches: [String] = []
            var iterator: OpaquePointer?

            let result = git_branch_iterator_new(&iterator, repoPtr, GIT_BRANCH_LOCAL)
            guard result == 0, let iter = iterator else { return [] }
            defer { git_branch_iterator_free(iter) }

            var ref: OpaquePointer?
            var branchType: git_branch_t = GIT_BRANCH_LOCAL

            while git_branch_next(&ref, &branchType, iter) == 0 {
                guard let r = ref else { continue }
                defer { git_reference_free(r) }

                var name: UnsafePointer<CChar>?
                if git_branch_name(&name, r) == 0, let n = name {
                    branches.append(String(cString: n))
                }
            }

            return branches
        } catch {
            print("❌ [LibGit2Service] getBranches error: \(error)")
            return []
        }
    }

    /// Switch to a different branch
    func checkout(branch: String, in repoURL: URL) -> Bool {
        let result = switchBranch(to: branch, in: repoURL)
        return result.success
    }

    /// Switch to a branch with error reporting
    func switchBranch(to branchName: String, in repoURL: URL) -> (success: Bool, error: String?) {
        print("🔀 [LibGit2Service] Switching to branch: \(branchName)")

        do {
            let repo = try LibGit2Repository(at: repoURL.path)
            guard let repoPtr = repo.pointer else {
                return (false, "Failed to open repository")
            }

            // Get the branch reference
            var branchRef: OpaquePointer?
            var result = git_branch_lookup(&branchRef, repoPtr, branchName, GIT_BRANCH_LOCAL)
            guard result == 0, let branch = branchRef else {
                return (false, "Branch '\(branchName)' not found")
            }
            defer { git_reference_free(branch) }

            // Get the commit the branch points to
            var commitOid = git_oid()
            guard let targetOid = git_reference_target(branch) else {
                return (false, "Failed to get branch target")
            }
            commitOid = targetOid.pointee

            var commit: OpaquePointer?
            result = git_commit_lookup(&commit, repoPtr, &commitOid)
            guard result == 0, let c = commit else {
                return (false, "Failed to lookup commit")
            }
            defer { git_commit_free(c) }

            // Checkout the commit
            var opts = git_checkout_options()
            git_checkout_options_init(&opts, UInt32(GIT_CHECKOUT_OPTIONS_VERSION))
            opts.checkout_strategy = GIT_CHECKOUT_SAFE.rawValue

            result = git_checkout_tree(repoPtr, c, &opts)
            guard result == 0 else {
                let error = LibGit2Error.lastError()
                return (false, "Checkout failed: \(error.message)")
            }

            // Update HEAD to point to the branch
            let refName = "refs/heads/\(branchName)"
            result = git_repository_set_head(repoPtr, refName)
            guard result == 0 else {
                let error = LibGit2Error.lastError()
                return (false, "Failed to update HEAD: \(error.message)")
            }

            print("✅ [LibGit2Service] Successfully switched to branch: \(branchName)")
            return (true, nil)
        } catch {
            return (false, error.localizedDescription)
        }
    }

    /// Create a new branch
    func createBranch(name: String, switchTo: Bool, in repoURL: URL) -> (success: Bool, error: String?) {
        do {
            let repo = try LibGit2Repository(at: repoURL.path)
            guard let repoPtr = repo.pointer else {
                return (false, "Failed to open repository")
            }

            // Get HEAD commit
            var headRef: OpaquePointer?
            var result = git_repository_head(&headRef, repoPtr)
            guard result == 0, let head = headRef else {
                return (false, "Failed to get HEAD")
            }
            defer { git_reference_free(head) }

            guard let targetOid = git_reference_target(head) else {
                return (false, "Failed to get HEAD target")
            }

            var commit: OpaquePointer?
            var oid = targetOid.pointee
            result = git_commit_lookup(&commit, repoPtr, &oid)
            guard result == 0, let c = commit else {
                return (false, "Failed to lookup HEAD commit")
            }
            defer { git_commit_free(c) }

            // Create the branch
            var newBranch: OpaquePointer?
            result = git_branch_create(&newBranch, repoPtr, name, c, 0)
            guard result == 0 else {
                let error = LibGit2Error.lastError()
                return (false, "Failed to create branch: \(error.message)")
            }
            if let nb = newBranch {
                git_reference_free(nb)
            }

            // Switch to it if requested
            if switchTo {
                return switchBranch(to: name, in: repoURL)
            }

            return (true, nil)
        } catch {
            return (false, error.localizedDescription)
        }
    }

    // MARK: - Remote URL Operations

    /// Get the remote URL for the repository
    func getRemoteURL(for repoURL: URL) -> (url: String?, isSSH: Bool) {
        do {
            let repo = try LibGit2Repository(at: repoURL.path)
            guard let repoPtr = repo.pointer else { return (nil, false) }

            var remote: OpaquePointer?
            let result = git_remote_lookup(&remote, repoPtr, "origin")
            guard result == 0, let r = remote else { return (nil, false) }
            defer { git_remote_free(r) }

            guard let urlPtr = git_remote_url(r) else { return (nil, false) }
            let remoteURL = String(cString: urlPtr)

            let isSSH = remoteURL.hasPrefix("git@")
            return (remoteURL, isSSH)
        } catch {
            return (nil, false)
        }
    }

    /// Convert git remote URL to web URL
    func convertToWebURL(_ remoteURL: String, branch: String?) -> String? {
        var webURL = remoteURL

        // Handle SSH format: git@github.com:user/repo.git -> https://github.com/user/repo
        if remoteURL.hasPrefix("git@") {
            let withoutGit = remoteURL.replacingOccurrences(of: "git@", with: "")
            let parts = withoutGit.split(separator: ":", maxSplits: 1)
            guard parts.count == 2 else { return nil }

            let host = String(parts[0])
            let path = String(parts[1])
            webURL = "https://\(host)/\(path)"
        }

        // Remove .git suffix if present
        if webURL.hasSuffix(".git") {
            webURL = String(webURL.dropLast(4))
        }

        // Add branch path if provided
        if let branch = branch {
            if webURL.contains("github.com") {
                webURL = "\(webURL)/tree/\(branch)"
            } else if webURL.contains("gitlab.com") {
                webURL = "\(webURL)/-/tree/\(branch)"
            } else if webURL.contains("bitbucket.org") {
                webURL = "\(webURL)/src/\(branch)"
            } else {
                webURL = "\(webURL)/tree/\(branch)"
            }
        }

        return webURL
    }

    // MARK: - Status Operations

    /// Get status for all changed files in the repository
    func getChangedFiles(for repoURL: URL) -> [GitChangedFile] {
        do {
            let repo = try LibGit2Repository(at: repoURL.path)
            guard let repoPtr = repo.pointer else { return [] }

            var statusList: OpaquePointer?
            var opts = git_status_options()
            git_status_options_init(&opts, UInt32(GIT_STATUS_OPTIONS_VERSION))
            opts.show = GIT_STATUS_SHOW_INDEX_AND_WORKDIR
            opts.flags = GIT_STATUS_OPT_INCLUDE_UNTRACKED.rawValue |
                        GIT_STATUS_OPT_RENAMES_HEAD_TO_INDEX.rawValue |
                        GIT_STATUS_OPT_SORT_CASE_SENSITIVELY.rawValue

            let result = git_status_list_new(&statusList, repoPtr, &opts)
            guard result == 0, let list = statusList else { return [] }
            defer { git_status_list_free(list) }

            var files: [GitChangedFile] = []
            let count = git_status_list_entrycount(list)

            for i in 0..<count {
                guard let entry = git_status_byindex(list, i) else { continue }

                let status = entry.pointee.status

                // Get file path
                let filePath: String
                if let indexToWorkdir = entry.pointee.index_to_workdir {
                    if let newFile = indexToWorkdir.pointee.new_file.path {
                        filePath = String(cString: newFile)
                    } else if let oldFile = indexToWorkdir.pointee.old_file.path {
                        filePath = String(cString: oldFile)
                    } else {
                        continue
                    }
                } else if let headToIndex = entry.pointee.head_to_index {
                    if let newFile = headToIndex.pointee.new_file.path {
                        filePath = String(cString: newFile)
                    } else if let oldFile = headToIndex.pointee.old_file.path {
                        filePath = String(cString: oldFile)
                    } else {
                        continue
                    }
                } else {
                    continue
                }

                let fileURL = repoURL.appendingPathComponent(filePath)

                // Parse staged changes (head_to_index)
                if status.rawValue & GIT_STATUS_INDEX_NEW.rawValue != 0 {
                    files.append(GitChangedFile(url: fileURL, status: .added, isStaged: true))
                } else if status.rawValue & GIT_STATUS_INDEX_MODIFIED.rawValue != 0 {
                    files.append(GitChangedFile(url: fileURL, status: .staged, isStaged: true))
                } else if status.rawValue & GIT_STATUS_INDEX_DELETED.rawValue != 0 {
                    files.append(GitChangedFile(url: fileURL, status: .stagedDeleted, isStaged: true))
                } else if status.rawValue & GIT_STATUS_INDEX_RENAMED.rawValue != 0 {
                    files.append(GitChangedFile(url: fileURL, status: .renamed, isStaged: true))
                }

                // Parse unstaged changes (index_to_workdir)
                if status.rawValue & GIT_STATUS_WT_NEW.rawValue != 0 {
                    files.append(GitChangedFile(url: fileURL, status: .untracked, isStaged: false))
                } else if status.rawValue & GIT_STATUS_WT_MODIFIED.rawValue != 0 {
                    files.append(GitChangedFile(url: fileURL, status: .modified, isStaged: false))
                } else if status.rawValue & GIT_STATUS_WT_DELETED.rawValue != 0 {
                    files.append(GitChangedFile(url: fileURL, status: .deleted, isStaged: false))
                }

                // Conflicts
                if status.rawValue & GIT_STATUS_CONFLICTED.rawValue != 0 {
                    files.append(GitChangedFile(url: fileURL, status: .unmerged, isStaged: false))
                }
            }

            return files
        } catch {
            print("❌ [LibGit2Service] getChangedFiles error: \(error)")
            return []
        }
    }

    /// Get status for a specific file
    func getFileStatus(for fileURL: URL, in repoURL: URL) -> GitFileStatus {
        let changedFiles = getChangedFiles(for: repoURL)
        return changedFiles.first { $0.url == fileURL }?.status ?? .clean
    }

    /// Get dictionary of file statuses for all files in repo
    func getFileStatuses(for repoURL: URL) -> [URL: GitFileStatus] {
        let changedFiles = getChangedFiles(for: repoURL)
        var statuses: [URL: GitFileStatus] = [:]

        for file in changedFiles {
            if !file.isStaged || statuses[file.url] == nil {
                statuses[file.url] = file.status
            }
        }

        return statuses
    }

    // MARK: - Staging Operations

    /// Stage files for commit
    func stageFiles(_ urls: [URL], in repoURL: URL) -> Bool {
        do {
            let repo = try LibGit2Repository(at: repoURL.path)
            guard let repoPtr = repo.pointer else { return false }

            var index: OpaquePointer?
            var result = git_repository_index(&index, repoPtr)
            guard result == 0, let idx = index else { return false }
            defer { git_index_free(idx) }

            for url in urls {
                let relativePath = url.path.replacingOccurrences(of: repoURL.path + "/", with: "")
                result = git_index_add_bypath(idx, relativePath)
                if result != 0 {
                    print("❌ [LibGit2Service] Failed to stage: \(relativePath)")
                }
            }

            // Write the index
            result = git_index_write(idx)
            return result == 0
        } catch {
            print("❌ [LibGit2Service] stageFiles error: \(error)")
            return false
        }
    }

    /// Stage all changes
    func stageAll(in repoURL: URL) -> Bool {
        do {
            let repo = try LibGit2Repository(at: repoURL.path)
            guard let repoPtr = repo.pointer else { return false }

            var index: OpaquePointer?
            var result = git_repository_index(&index, repoPtr)
            guard result == 0, let idx = index else { return false }
            defer { git_index_free(idx) }

            // Add all changes
            result = git_index_add_all(idx, nil, GIT_INDEX_ADD_DEFAULT.rawValue, nil, nil)
            guard result == 0 else { return false }

            result = git_index_write(idx)
            return result == 0
        } catch {
            print("❌ [LibGit2Service] stageAll error: \(error)")
            return false
        }
    }

    /// Unstage files
    func unstageFiles(_ urls: [URL], in repoURL: URL) -> Bool {
        do {
            let repo = try LibGit2Repository(at: repoURL.path)
            guard let repoPtr = repo.pointer else { return false }

            // Get HEAD commit
            var headRef: OpaquePointer?
            var result = git_repository_head(&headRef, repoPtr)

            // If no HEAD (empty repo), just remove from index
            if result != 0 {
                var index: OpaquePointer?
                result = git_repository_index(&index, repoPtr)
                guard result == 0, let idx = index else { return false }
                defer { git_index_free(idx) }

                for url in urls {
                    let relativePath = url.path.replacingOccurrences(of: repoURL.path + "/", with: "")
                    git_index_remove_bypath(idx, relativePath)
                }

                return git_index_write(idx) == 0
            }

            guard let head = headRef else { return false }
            defer { git_reference_free(head) }

            guard let targetOid = git_reference_target(head) else { return false }

            var commit: OpaquePointer?
            var oid = targetOid.pointee
            result = git_commit_lookup(&commit, repoPtr, &oid)
            guard result == 0, let c = commit else { return false }
            defer { git_commit_free(c) }

            // Reset paths to HEAD
            for url in urls {
                let relativePath = url.path.replacingOccurrences(of: repoURL.path + "/", with: "")
                var pathspec = git_strarray()

                relativePath.withCString { cstr in
                    var pathPtr: UnsafeMutablePointer<Int8>? = strdup(cstr)
                    pathspec.strings = withUnsafeMutablePointer(to: &pathPtr) { $0 }
                    pathspec.count = 1

                    git_reset_default(repoPtr, c, &pathspec)
                    free(pathPtr)
                }
            }

            return true
        } catch {
            print("❌ [LibGit2Service] unstageFiles error: \(error)")
            return false
        }
    }

    /// Unstage all files
    func unstageAll(in repoURL: URL) -> Bool {
        let changedFiles = getChangedFiles(for: repoURL).filter { $0.isStaged }
        let urls = changedFiles.map { $0.url }
        return unstageFiles(urls, in: repoURL)
    }

    /// Discard changes to files (restore to HEAD)
    func discardChanges(_ urls: [URL], in repoURL: URL) -> Bool {
        do {
            let repo = try LibGit2Repository(at: repoURL.path)
            guard let repoPtr = repo.pointer else { return false }

            var opts = git_checkout_options()
            git_checkout_options_init(&opts, UInt32(GIT_CHECKOUT_OPTIONS_VERSION))
            opts.checkout_strategy = GIT_CHECKOUT_FORCE.rawValue

            // Build pathspec
            let paths = urls.map { $0.path.replacingOccurrences(of: repoURL.path + "/", with: "") }

            var pathPtrs = paths.map { strdup($0) }
            defer { pathPtrs.forEach { free($0) } }

            var pathspec = git_strarray()
            pathspec.count = paths.count
            pathspec.strings = UnsafeMutablePointer(mutating: pathPtrs)
            opts.paths = pathspec

            let result = git_checkout_head(repoPtr, &opts)
            return result == 0
        } catch {
            print("❌ [LibGit2Service] discardChanges error: \(error)")
            return false
        }
    }

    // MARK: - Signature Helpers

    /// Get git signature with fallback mechanisms for sandboxed environments
    /// 1. Try git_signature_default (reads from .gitconfig)
    /// 2. Try reading from repo's local .git/config
    /// 3. Fall back to macOS account name
    private func getSignature(for repoPtr: OpaquePointer) -> UnsafeMutablePointer<git_signature>? {
        var signature: UnsafeMutablePointer<git_signature>?

        // Try 1: Default signature from git config
        if git_signature_default(&signature, repoPtr) == 0 {
            return signature
        }

        // Try 2: Read from repo's local config
        var config: OpaquePointer?
        if git_repository_config(&config, repoPtr) == 0, let cfg = config {
            defer { git_config_free(cfg) }

            var namePtr: UnsafePointer<Int8>?
            var emailPtr: UnsafePointer<Int8>?

            let hasName = git_config_get_string(&namePtr, cfg, "user.name") == 0
            let hasEmail = git_config_get_string(&emailPtr, cfg, "user.email") == 0

            if hasName, hasEmail, let name = namePtr, let email = emailPtr {
                let nameStr = String(cString: name)
                let emailStr = String(cString: email)
                if git_signature_now(&signature, nameStr, emailStr) == 0 {
                    return signature
                }
            }
        }

        // Try 3: Fallback to macOS account name
        let fallbackName = NSFullUserName().isEmpty ? NSUserName() : NSFullUserName()
        let fallbackEmail = "\(NSUserName())@localhost"

        if git_signature_now(&signature, fallbackName, fallbackEmail) == 0 {
            print("⚠️ [LibGit2Service] Using fallback signature: \(fallbackName) <\(fallbackEmail)>")
            return signature
        }

        return nil
    }

    // MARK: - Commit Operations

    /// Commit staged changes with message
    func commit(message: String, in repoURL: URL) -> (success: Bool, error: String?) {
        do {
            let repo = try LibGit2Repository(at: repoURL.path)
            guard let repoPtr = repo.pointer else {
                return (false, "Failed to open repository")
            }

            // Get index
            var index: OpaquePointer?
            var result = git_repository_index(&index, repoPtr)
            guard result == 0, let idx = index else {
                return (false, "Failed to get index")
            }
            defer { git_index_free(idx) }

            // Write tree from index
            var treeOid = git_oid()
            result = git_index_write_tree(&treeOid, idx)
            guard result == 0 else {
                let error = LibGit2Error.lastError()
                return (false, "Failed to write tree: \(error.message)")
            }

            var tree: OpaquePointer?
            result = git_tree_lookup(&tree, repoPtr, &treeOid)
            guard result == 0, let t = tree else {
                return (false, "Failed to lookup tree")
            }
            defer { git_tree_free(t) }

            // Get signature (with fallback for sandboxed environments)
            guard let sig = getSignature(for: repoPtr) else {
                return (false, "Failed to get signature. Please configure user.name and user.email in the repository's .git/config")
            }
            defer { git_signature_free(sig) }

            // Get parent commit (HEAD)
            var parentCommit: OpaquePointer?
            var headRef: OpaquePointer?
            let hasHead = git_repository_head(&headRef, repoPtr) == 0

            if hasHead, let head = headRef {
                defer { git_reference_free(head) }
                if let targetOid = git_reference_target(head) {
                    var parentOid = targetOid.pointee
                    git_commit_lookup(&parentCommit, repoPtr, &parentOid)
                }
            }

            // Create commit
            var commitOid = git_oid()

            if let parent = parentCommit {
                defer { git_commit_free(parent) }
                // Use withUnsafePointer to get proper pointer types
                var parentPtr: OpaquePointer? = parent
                result = withUnsafeMutablePointer(to: &parentPtr) { parentsPtr in
                    git_commit_create(
                        &commitOid,
                        repoPtr,
                        "HEAD",
                        sig,
                        sig,
                        nil, // Use default encoding
                        message,
                        t,
                        1,
                        parentsPtr
                    )
                }
            } else {
                result = git_commit_create(
                    &commitOid,
                    repoPtr,
                    "HEAD",
                    sig,
                    sig,
                    nil,
                    message,
                    t,
                    0,
                    nil
                )
            }

            guard result == 0 else {
                let error = LibGit2Error.lastError()
                return (false, "Commit failed: \(error.message)")
            }

            return (true, nil)
        } catch {
            return (false, error.localizedDescription)
        }
    }

    // MARK: - Remote Operations

    /// Push to remote
    func push(in repoURL: URL) -> (success: Bool, error: String?, alreadyUpToDate: Bool) {
        do {
            let repo = try LibGit2Repository(at: repoURL.path)
            guard let repoPtr = repo.pointer else {
                return (false, "Failed to open repository", false)
            }

            // Get current branch
            guard let branchName = getCurrentBranch(for: repoURL) else {
                return (false, "Not on a branch", false)
            }

            // Get remote
            var remote: OpaquePointer?
            var result = git_remote_lookup(&remote, repoPtr, "origin")
            guard result == 0, let r = remote else {
                return (false, "Remote 'origin' not found", false)
            }
            defer { git_remote_free(r) }

            // Build refspec
            let refspec = "refs/heads/\(branchName):refs/heads/\(branchName)"
            var refspecs = git_strarray()
            var refspecPtr = strdup(refspec)
            defer { free(refspecPtr) }
            refspecs.strings = withUnsafeMutablePointer(to: &refspecPtr) { $0 }
            refspecs.count = 1

            // Push options
            var opts = git_push_options()
            git_push_options_init(&opts, UInt32(GIT_PUSH_OPTIONS_VERSION))

            // Set up credentials callback for SSH
            opts.callbacks.credentials = { (out, url, username_from_url, allowed_types, payload) -> Int32 in
                // Try SSH agent first
                if allowed_types & GIT_CREDENTIAL_SSH_KEY.rawValue != 0 {
                    return git_credential_ssh_key_from_agent(out, username_from_url)
                }
                return GIT_PASSTHROUGH.rawValue
            }

            result = git_remote_push(r, &refspecs, &opts)

            if result == 0 {
                return (true, nil, false)
            } else {
                let error = LibGit2Error.lastError()

                // Check for up-to-date
                if error.message.lowercased().contains("up-to-date") ||
                   error.message.lowercased().contains("up to date") {
                    return (true, nil, true)
                }

                let userFriendly = LibGit2Error.userFriendlyMessage(for: error.message)
                return (false, "Push failed: \(userFriendly)", false)
            }
        } catch {
            let userFriendly = LibGit2Error.userFriendlyMessage(for: error.localizedDescription)
            return (false, userFriendly, false)
        }
    }

    /// Pull from remote (fetch + merge)
    func pull(in repoURL: URL) -> (success: Bool, error: String?) {
        // First fetch
        let fetchResult = fetch(in: repoURL)
        if !fetchResult.success {
            return fetchResult
        }

        // Then merge
        return merge(in: repoURL)
    }

    /// Fetch from remote
    func fetch(in repoURL: URL) -> (success: Bool, error: String?) {
        do {
            let repo = try LibGit2Repository(at: repoURL.path)
            guard let repoPtr = repo.pointer else {
                return (false, "Failed to open repository")
            }

            var remote: OpaquePointer?
            var result = git_remote_lookup(&remote, repoPtr, "origin")
            guard result == 0, let r = remote else {
                return (false, "Remote 'origin' not found")
            }
            defer { git_remote_free(r) }

            var opts = git_fetch_options()
            git_fetch_options_init(&opts, UInt32(GIT_FETCH_OPTIONS_VERSION))

            // Set up credentials callback
            opts.callbacks.credentials = { (out, url, username_from_url, allowed_types, payload) -> Int32 in
                if allowed_types & GIT_CREDENTIAL_SSH_KEY.rawValue != 0 {
                    return git_credential_ssh_key_from_agent(out, username_from_url)
                }
                return GIT_PASSTHROUGH.rawValue
            }

            result = git_remote_fetch(r, nil, &opts, nil)

            if result == 0 {
                return (true, nil)
            } else {
                let error = LibGit2Error.lastError()
                let userFriendly = LibGit2Error.userFriendlyMessage(for: error.message)
                return (false, "Fetch failed: \(userFriendly)")
            }
        } catch {
            let userFriendly = LibGit2Error.userFriendlyMessage(for: error.localizedDescription)
            return (false, userFriendly)
        }
    }

    /// Merge upstream into current branch
    private func merge(in repoURL: URL) -> (success: Bool, error: String?) {
        do {
            let repo = try LibGit2Repository(at: repoURL.path)
            guard let repoPtr = repo.pointer else {
                return (false, "Failed to open repository")
            }

            guard let branchName = getCurrentBranch(for: repoURL) else {
                return (false, "Not on a branch")
            }

            // Get upstream ref
            let upstreamRef = "refs/remotes/origin/\(branchName)"
            var annotatedCommit: OpaquePointer?
            var result = git_annotated_commit_from_revspec(&annotatedCommit, repoPtr, upstreamRef)

            guard result == 0, let ac = annotatedCommit else {
                // No upstream, nothing to merge
                return (true, nil)
            }
            defer { git_annotated_commit_free(ac) }

            // Perform merge analysis
            var analysis = git_merge_analysis_t(rawValue: 0)
            var preference = git_merge_preference_t(rawValue: 0)

            var acPtr: OpaquePointer? = ac
            result = withUnsafeMutablePointer(to: &acPtr) { headsPtr in
                git_merge_analysis(&analysis, &preference, repoPtr, headsPtr, 1)
            }

            if analysis.rawValue & GIT_MERGE_ANALYSIS_UP_TO_DATE.rawValue != 0 {
                return (true, nil) // Already up to date
            }

            if analysis.rawValue & GIT_MERGE_ANALYSIS_FASTFORWARD.rawValue != 0 {
                // Fast-forward merge
                let targetOid = git_annotated_commit_id(ac)
                guard let oid = targetOid else {
                    return (false, "Failed to get merge target")
                }

                var target: OpaquePointer?
                var oidCopy = oid.pointee
                result = git_object_lookup(&target, repoPtr, &oidCopy, GIT_OBJECT_COMMIT)
                guard result == 0, let t = target else {
                    return (false, "Failed to lookup target")
                }
                defer { git_object_free(t) }

                var opts = git_checkout_options()
                git_checkout_options_init(&opts, UInt32(GIT_CHECKOUT_OPTIONS_VERSION))
                opts.checkout_strategy = GIT_CHECKOUT_SAFE.rawValue

                result = git_checkout_tree(repoPtr, t, &opts)
                guard result == 0 else {
                    let error = LibGit2Error.lastError()
                    return (false, "Checkout failed: \(error.message)")
                }

                // Update HEAD
                var newRef: OpaquePointer?
                git_reference_set_target(&newRef, nil, &oidCopy, "pull: fast-forward")
                if let ref = newRef {
                    git_reference_free(ref)
                }

                let refName = "refs/heads/\(branchName)"
                result = git_repository_set_head(repoPtr, refName)

                return (true, nil)
            }

            if analysis.rawValue & GIT_MERGE_ANALYSIS_NORMAL.rawValue != 0 {
                // Normal merge - more complex, for now return error suggesting manual resolution
                return (false, "Merge required. Please use git command line to merge manually.")
            }

            return (true, nil)
        } catch {
            return (false, error.localizedDescription)
        }
    }

    /// Check if there are unpushed commits
    func hasUnpushedCommits(in repoURL: URL) -> Bool {
        do {
            let repo = try LibGit2Repository(at: repoURL.path)
            guard let repoPtr = repo.pointer else { return false }

            guard let branchName = getCurrentBranch(for: repoURL) else { return false }

            // Get local branch ref
            var localRef: OpaquePointer?
            let localRefName = "refs/heads/\(branchName)"
            var result = git_reference_lookup(&localRef, repoPtr, localRefName)
            guard result == 0, let local = localRef else { return false }
            defer { git_reference_free(local) }

            // Get remote tracking branch
            var remoteRef: OpaquePointer?
            let remoteRefName = "refs/remotes/origin/\(branchName)"
            result = git_reference_lookup(&remoteRef, repoPtr, remoteRefName)
            guard result == 0, let remote = remoteRef else { return true } // No remote = unpushed
            defer { git_reference_free(remote) }

            // Compare OIDs
            guard let localOid = git_reference_target(local),
                  let remoteOid = git_reference_target(remote) else { return false }

            return git_oid_cmp(localOid, remoteOid) != 0
        } catch {
            return false
        }
    }

    /// Check if there are commits to pull
    func hasUnpulledCommits(in repoURL: URL) -> Bool {
        // Fetch first
        _ = fetch(in: repoURL)

        do {
            let repo = try LibGit2Repository(at: repoURL.path)
            guard let repoPtr = repo.pointer else { return false }

            guard let branchName = getCurrentBranch(for: repoURL) else { return false }

            // Get local and remote refs
            var localRef: OpaquePointer?
            let localRefName = "refs/heads/\(branchName)"
            var result = git_reference_lookup(&localRef, repoPtr, localRefName)
            guard result == 0, let local = localRef else { return false }
            defer { git_reference_free(local) }

            var remoteRef: OpaquePointer?
            let remoteRefName = "refs/remotes/origin/\(branchName)"
            result = git_reference_lookup(&remoteRef, repoPtr, remoteRefName)
            guard result == 0, let remote = remoteRef else { return false }
            defer { git_reference_free(remote) }

            guard let localOid = git_reference_target(local),
                  let remoteOid = git_reference_target(remote) else { return false }

            // Check if remote is ahead
            var ahead: Int = 0
            var behind: Int = 0
            var localOidCopy = localOid.pointee
            var remoteOidCopy = remoteOid.pointee

            result = git_graph_ahead_behind(&ahead, &behind, repoPtr, &localOidCopy, &remoteOidCopy)

            return behind > 0
        } catch {
            return false
        }
    }

    // MARK: - Diff Operations

    /// Get diff for a file
    func getDiff(for fileURL: URL, in repoURL: URL, staged: Bool = false) -> String? {
        do {
            let repo = try LibGit2Repository(at: repoURL.path)
            guard let repoPtr = repo.pointer else { return nil }

            let relativePath = fileURL.path.replacingOccurrences(of: repoURL.path + "/", with: "")

            var diff: OpaquePointer?
            var opts = git_diff_options()
            git_diff_options_init(&opts, UInt32(GIT_DIFF_OPTIONS_VERSION))

            // Set pathspec to filter to this file
            var pathPtr = strdup(relativePath)
            defer { free(pathPtr) }
            opts.pathspec.strings = withUnsafeMutablePointer(to: &pathPtr) { $0 }
            opts.pathspec.count = 1

            var result: Int32
            if staged {
                // Staged: HEAD to index
                var headTree: OpaquePointer?
                var headRef: OpaquePointer?

                if git_repository_head(&headRef, repoPtr) == 0, let head = headRef {
                    defer { git_reference_free(head) }
                    if let targetOid = git_reference_target(head) {
                        var commit: OpaquePointer?
                        var oid = targetOid.pointee
                        if git_commit_lookup(&commit, repoPtr, &oid) == 0, let c = commit {
                            defer { git_commit_free(c) }
                            git_commit_tree(&headTree, c)
                        }
                    }
                }

                result = git_diff_tree_to_index(&diff, repoPtr, headTree, nil, &opts)
                if let tree = headTree {
                    git_tree_free(tree)
                }
            } else {
                // Unstaged: index to workdir
                result = git_diff_index_to_workdir(&diff, repoPtr, nil, &opts)
            }

            guard result == 0, let d = diff else { return nil }
            defer { git_diff_free(d) }

            // Convert diff to string
            var buf = git_buf()
            result = git_diff_to_buf(&buf, d, GIT_DIFF_FORMAT_PATCH)
            defer { git_buf_dispose(&buf) }

            guard result == 0, let ptr = buf.ptr else { return nil }
            return String(cString: ptr)
        } catch {
            print("❌ [LibGit2Service] getDiff error: \(error)")
            return nil
        }
    }

    /// Check if a file is tracked by git
    func isFileTracked(_ fileURL: URL, in repoURL: URL) -> Bool {
        do {
            let repo = try LibGit2Repository(at: repoURL.path)
            guard let repoPtr = repo.pointer else { return false }

            let relativePath = fileURL.path.replacingOccurrences(of: repoURL.path + "/", with: "")

            var index: OpaquePointer?
            let result = git_repository_index(&index, repoPtr)
            guard result == 0, let idx = index else { return false }
            defer { git_index_free(idx) }

            // Check if file is in index
            let entry = git_index_get_bypath(idx, relativePath, 0)
            return entry != nil
        } catch {
            return false
        }
    }

    /// Move a file using git mv (preserves history)
    func moveFile(from sourceURL: URL, to destinationURL: URL, in repoURL: URL) -> Bool {
        do {
            let repo = try LibGit2Repository(at: repoURL.path)
            guard let repoPtr = repo.pointer else { return false }

            let sourcePath = sourceURL.path.replacingOccurrences(of: repoURL.path + "/", with: "")
            let destPath = destinationURL.path.replacingOccurrences(of: repoURL.path + "/", with: "")

            var index: OpaquePointer?
            var result = git_repository_index(&index, repoPtr)
            guard result == 0, let idx = index else { return false }
            defer { git_index_free(idx) }

            // Remove old entry
            result = git_index_remove_bypath(idx, sourcePath)
            guard result == 0 else { return false }

            // Add new entry
            result = git_index_add_bypath(idx, destPath)
            guard result == 0 else { return false }

            // Write index
            result = git_index_write(idx)
            return result == 0
        } catch {
            return false
        }
    }

    // MARK: - Commit History Operations

    /// Get commit log with pagination
    func getCommitLog(for repoURL: URL, limit: Int = 100, offset: Int = 0) -> [GitCommit] {
        do {
            let repo = try LibGit2Repository(at: repoURL.path)
            guard let repoPtr = repo.pointer else { return [] }

            var walker: OpaquePointer?
            var result = git_revwalk_new(&walker, repoPtr)
            guard result == 0, let w = walker else { return [] }
            defer { git_revwalk_free(w) }

            // Push HEAD
            result = git_revwalk_push_head(w)
            guard result == 0 else { return [] }

            // Sort by time
            git_revwalk_sorting(w, GIT_SORT_TIME.rawValue)

            var commits: [GitCommit] = []
            var oid = git_oid()
            var count = 0
            var skipped = 0

            while git_revwalk_next(&oid, w) == 0 {
                // Skip for offset
                if skipped < offset {
                    skipped += 1
                    continue
                }

                // Stop at limit
                if count >= limit {
                    break
                }

                var commit: OpaquePointer?
                result = git_commit_lookup(&commit, repoPtr, &oid)
                guard result == 0, let c = commit else { continue }
                defer { git_commit_free(c) }

                // Get commit info
                var hashBuffer = [CChar](repeating: 0, count: 41)
                git_oid_tostr(&hashBuffer, 41, &oid)
                let hash = String(cString: hashBuffer)
                let shortHash = String(hash.prefix(7))

                let author: String
                let email: String
                let date: Date

                if let sig = git_commit_author(c) {
                    author = sig.pointee.name.map { String(cString: $0) } ?? "Unknown"
                    email = sig.pointee.email.map { String(cString: $0) } ?? ""
                    date = Date(timeIntervalSince1970: TimeInterval(sig.pointee.when.time))
                } else {
                    author = "Unknown"
                    email = ""
                    date = Date()
                }

                let message = git_commit_message(c).map { String(cString: $0) } ?? ""

                let gitCommit = GitCommit(
                    hash: hash,
                    shortHash: shortHash,
                    author: author,
                    email: email,
                    date: date,
                    message: message.trimmingCharacters(in: .whitespacesAndNewlines)
                )
                commits.append(gitCommit)
                count += 1
            }

            return commits
        } catch {
            print("❌ [LibGit2Service] getCommitLog error: \(error)")
            return []
        }
    }

    /// Get diff for a specific commit
    func getCommitDiff(hash: String, in repoURL: URL) -> String? {
        do {
            let repo = try LibGit2Repository(at: repoURL.path)
            guard let repoPtr = repo.pointer else { return nil }

            var oid = git_oid()
            var result = git_oid_fromstr(&oid, hash)
            guard result == 0 else { return nil }

            var commit: OpaquePointer?
            result = git_commit_lookup(&commit, repoPtr, &oid)
            guard result == 0, let c = commit else { return nil }
            defer { git_commit_free(c) }

            // Get commit tree
            var tree: OpaquePointer?
            result = git_commit_tree(&tree, c)
            guard result == 0, let t = tree else { return nil }
            defer { git_tree_free(t) }

            // Get parent tree (if exists)
            var parentTree: OpaquePointer?
            if git_commit_parentcount(c) > 0 {
                var parent: OpaquePointer?
                if git_commit_parent(&parent, c, 0) == 0, let p = parent {
                    defer { git_commit_free(p) }
                    git_commit_tree(&parentTree, p)
                }
            }
            defer { if let pt = parentTree { git_tree_free(pt) } }

            // Get diff
            var diff: OpaquePointer?
            result = git_diff_tree_to_tree(&diff, repoPtr, parentTree, t, nil)
            guard result == 0, let d = diff else { return nil }
            defer { git_diff_free(d) }

            // Build output string
            var output = ""

            // Add commit header
            let author = git_commit_author(c)
            let authorName = author?.pointee.name.map { String(cString: $0) } ?? "Unknown"
            let authorEmail = author?.pointee.email.map { String(cString: $0) } ?? ""
            let message = git_commit_message(c).map { String(cString: $0) } ?? ""
            let date = author.map { Date(timeIntervalSince1970: TimeInterval($0.pointee.when.time)) } ?? Date()

            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short

            output += "commit \(hash)\n"
            output += "Author: \(authorName) <\(authorEmail)>\n"
            output += "Date:   \(formatter.string(from: date))\n\n"
            output += "    \(message.trimmingCharacters(in: .whitespacesAndNewlines))\n\n"

            // Add diff
            var buf = git_buf()
            result = git_diff_to_buf(&buf, d, GIT_DIFF_FORMAT_PATCH)
            defer { git_buf_dispose(&buf) }

            if result == 0, let ptr = buf.ptr {
                output += String(cString: ptr)
            }

            return output
        } catch {
            return nil
        }
    }

    /// Get list of files changed in a commit
    func getCommitFiles(hash: String, in repoURL: URL) -> [String] {
        do {
            let repo = try LibGit2Repository(at: repoURL.path)
            guard let repoPtr = repo.pointer else { return [] }

            var oid = git_oid()
            var result = git_oid_fromstr(&oid, hash)
            guard result == 0 else { return [] }

            var commit: OpaquePointer?
            result = git_commit_lookup(&commit, repoPtr, &oid)
            guard result == 0, let c = commit else { return [] }
            defer { git_commit_free(c) }

            var tree: OpaquePointer?
            result = git_commit_tree(&tree, c)
            guard result == 0, let t = tree else { return [] }
            defer { git_tree_free(t) }

            var parentTree: OpaquePointer?
            if git_commit_parentcount(c) > 0 {
                var parent: OpaquePointer?
                if git_commit_parent(&parent, c, 0) == 0, let p = parent {
                    defer { git_commit_free(p) }
                    git_commit_tree(&parentTree, p)
                }
            }
            defer { if let pt = parentTree { git_tree_free(pt) } }

            var diff: OpaquePointer?
            result = git_diff_tree_to_tree(&diff, repoPtr, parentTree, t, nil)
            guard result == 0, let d = diff else { return [] }
            defer { git_diff_free(d) }

            var files: [String] = []
            let numDeltas = git_diff_num_deltas(d)

            for i in 0..<numDeltas {
                guard let delta = git_diff_get_delta(d, i) else { continue }
                if let newPath = delta.pointee.new_file.path {
                    files.append(String(cString: newPath))
                }
            }

            return files
        } catch {
            return []
        }
    }
}
