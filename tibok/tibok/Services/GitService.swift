//
//  GitService.swift
//  tibok
//
//  Git integration service for executing git commands and parsing results.
//

import Foundation

// MARK: - Git File Status

enum GitFileStatus: Hashable {
    case untracked      // ? - New file not in git
    case modified       // M - Modified in working tree (unstaged)
    case added          // A - Staged new file
    case deleted        // D - Deleted
    case renamed        // R - Renamed
    case copied         // C - Copied
    case unmerged       // U - Conflict
    case ignored        // ! - In .gitignore
    case staged         // Staged modification
    case stagedDeleted  // Staged deletion
    case clean          // No changes

    var color: String {
        switch self {
        case .modified: return "blue"
        case .added, .staged: return "green"
        case .untracked: return "yellow"
        case .unmerged: return "red"
        case .deleted, .stagedDeleted: return "gray"
        default: return "clear"
        }
    }

    var displayName: String {
        switch self {
        case .untracked: return "Untracked"
        case .modified: return "Modified"
        case .added: return "Added"
        case .deleted: return "Deleted"
        case .renamed: return "Renamed"
        case .copied: return "Copied"
        case .unmerged: return "Conflict"
        case .ignored: return "Ignored"
        case .staged: return "Staged"
        case .stagedDeleted: return "Deleted (staged)"
        case .clean: return "Clean"
        }
    }

    var isStaged: Bool {
        switch self {
        case .added, .staged, .stagedDeleted, .renamed, .copied:
            return true
        default:
            return false
        }
    }
}

// MARK: - Git Changed File

struct GitChangedFile: Identifiable, Hashable {
    let id: URL
    let url: URL
    let filename: String
    let status: GitFileStatus
    let isStaged: Bool

    init(url: URL, status: GitFileStatus, isStaged: Bool) {
        self.id = url
        self.url = url
        self.filename = url.lastPathComponent
        self.status = status
        self.isStaged = isStaged
    }
}

// MARK: - Git Service

@MainActor
class GitService: ObservableObject {
    static let shared = GitService()

    private init() {}

    // MARK: - Repository Detection

    /// Check if directory is inside a git repository
    func isGitRepository(at url: URL) -> Bool {
        return getRepositoryRoot(for: url) != nil
    }

    /// Get the root directory of the git repository containing the given path
    func getRepositoryRoot(for url: URL) -> URL? {
        print("🔍 [GitService] Detecting git repo in: \(url.path)")

        // In sandboxed environment, use FileManager to check for .git directory
        // This bypasses sandbox restrictions on running git commands
        var currentURL = url
        let fileManager = FileManager.default

        // Search up the directory tree for .git
        while currentURL.path != "/" {
            let gitURL = currentURL.appendingPathComponent(".git")
            var isDirectory: ObjCBool = false

            if fileManager.fileExists(atPath: gitURL.path, isDirectory: &isDirectory) {
                if isDirectory.boolValue {
                    print("✅ [GitService] Git repo found: \(currentURL.path)")
                    return currentURL
                }
            }

            // Move up one directory
            currentURL = currentURL.deletingLastPathComponent()
        }

        print("❌ [GitService] No git repository found")
        return nil
    }

    // MARK: - Branch Operations

    /// Get the current branch name
    func getCurrentBranch(for repoURL: URL) -> String? {
        let result = runGitCommand(["branch", "--show-current"], in: repoURL)
        guard let output = result.output, result.exitCode == 0 else {
            return nil
        }
        let branch = output.trimmingCharacters(in: .whitespacesAndNewlines)
        return branch.isEmpty ? nil : branch
    }

    /// Get list of all local branches
    func getBranches(for repoURL: URL) -> [String] {
        let result = runGitCommand(["branch", "--format=%(refname:short)"], in: repoURL)
        guard let output = result.output, result.exitCode == 0 else {
            return []
        }
        return output.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    /// Switch to a different branch
    func checkout(branch: String, in repoURL: URL) -> Bool {
        let result = runGitCommand(["checkout", branch], in: repoURL)
        return result.exitCode == 0
    }

    /// Switch to a branch with error reporting
    func switchBranch(to branchName: String, in repoURL: URL) -> (success: Bool, error: String?) {
        print("🔀 [GitService] Switching to branch: \(branchName)")
        print("   Repository: \(repoURL.path)")

        let result = runGitCommand(["checkout", branchName], in: repoURL)

        if result.exitCode == 0 {
            print("✅ [GitService] Successfully switched to branch: \(branchName)")
            return (true, nil)
        } else {
            print("❌ [GitService] Branch switch failed:")
            print("   Exit code: \(result.exitCode)")
            if let error = result.error {
                print("   Error: \(error)")
            }
            return (false, result.error ?? "Failed to switch branch")
        }
    }

    /// Create a new branch
    func createBranch(name: String, switchTo: Bool, in repoURL: URL) -> (success: Bool, error: String?) {
        // Create the branch
        let createResult = runGitCommand(["branch", name], in: repoURL)
        if createResult.exitCode != 0 {
            return (false, createResult.error ?? "Failed to create branch")
        }

        // Switch to it if requested
        if switchTo {
            let checkoutResult = runGitCommand(["checkout", name], in: repoURL)
            if checkoutResult.exitCode != 0 {
                return (false, checkoutResult.error ?? "Created branch but failed to switch to it")
            }
        }

        return (true, nil)
    }

    // MARK: - Remote Operations (URL)

    /// Get the remote URL for the repository
    /// Returns both the raw URL and whether it's SSH format
    func getRemoteURL(for repoURL: URL) -> (url: String?, isSSH: Bool) {
        // First try 'origin' remote
        let result = runGitCommand(["config", "--get", "remote.origin.url"], in: repoURL)

        guard let remoteURL = result.output?.trimmingCharacters(in: .whitespacesAndNewlines),
              !remoteURL.isEmpty,
              result.exitCode == 0 else {
            return (nil, false)
        }

        let isSSH = remoteURL.hasPrefix("git@")
        return (remoteURL, isSSH)
    }

    /// Convert git remote URL to web URL
    /// Handles SSH (git@github.com:user/repo.git) and HTTPS formats
    func convertToWebURL(_ remoteURL: String, branch: String?) -> String? {
        var webURL = remoteURL

        // Handle SSH format: git@github.com:user/repo.git -> https://github.com/user/repo
        if remoteURL.hasPrefix("git@") {
            // Extract host and path
            // Format: git@HOST:PATH
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
            // Try to detect host for branch URL format
            if webURL.contains("github.com") {
                webURL = "\(webURL)/tree/\(branch)"
            } else if webURL.contains("gitlab.com") {
                webURL = "\(webURL)/-/tree/\(branch)"
            } else if webURL.contains("bitbucket.org") {
                webURL = "\(webURL)/src/\(branch)"
            } else {
                // Generic fallback - just append branch
                webURL = "\(webURL)/tree/\(branch)"
            }
        }

        return webURL
    }

    // MARK: - Status Operations

    /// Get status for all changed files in the repository
    func getChangedFiles(for repoURL: URL) -> [GitChangedFile] {
        let result = runGitCommand(["status", "--porcelain", "-uall"], in: repoURL)
        guard let output = result.output, result.exitCode == 0 else {
            return []
        }

        var files: [GitChangedFile] = []

        for line in output.components(separatedBy: .newlines) {
            guard line.count >= 3 else { continue }

            let indexStatus = line[line.startIndex]
            let workTreeStatus = line[line.index(after: line.startIndex)]
            let filePath = String(line.dropFirst(3))

            // Handle renames (format: "R  old -> new")
            let actualPath: String
            if filePath.contains(" -> ") {
                actualPath = String(filePath.split(separator: " -> ").last ?? Substring(filePath))
            } else {
                actualPath = filePath
            }

            let fileURL = repoURL.appendingPathComponent(actualPath)

            // Parse staged status (index column)
            if indexStatus != " " && indexStatus != "?" {
                let status = parseGitStatus(index: indexStatus, workTree: " ")
                if status != .clean {
                    files.append(GitChangedFile(url: fileURL, status: status, isStaged: true))
                }
            }

            // Parse unstaged status (work tree column)
            if workTreeStatus != " " || indexStatus == "?" {
                let status = parseGitStatus(index: indexStatus, workTree: workTreeStatus)
                if status != .clean {
                    // Don't duplicate if already added as staged
                    if !files.contains(where: { $0.url == fileURL && $0.isStaged }) || workTreeStatus != " " {
                        files.append(GitChangedFile(url: fileURL, status: status, isStaged: false))
                    }
                }
            }
        }

        return files
    }

    /// Get status for a specific file
    func getFileStatus(for fileURL: URL, in repoURL: URL) -> GitFileStatus {
        let relativePath = fileURL.path.replacingOccurrences(of: repoURL.path + "/", with: "")
        let result = runGitCommand(["status", "--porcelain", relativePath], in: repoURL)

        guard let output = result.output, result.exitCode == 0 else {
            return .clean
        }

        let line = output.trimmingCharacters(in: .whitespacesAndNewlines)
        guard line.count >= 2 else {
            return .clean
        }

        let indexStatus = line[line.startIndex]
        let workTreeStatus = line[line.index(after: line.startIndex)]

        return parseGitStatus(index: indexStatus, workTree: workTreeStatus)
    }

    /// Get dictionary of file statuses for all files in repo
    func getFileStatuses(for repoURL: URL) -> [URL: GitFileStatus] {
        let changedFiles = getChangedFiles(for: repoURL)
        var statuses: [URL: GitFileStatus] = [:]

        for file in changedFiles {
            // Prefer unstaged status for display (shows current working tree state)
            if !file.isStaged || statuses[file.url] == nil {
                statuses[file.url] = file.status
            }
        }

        return statuses
    }

    private func parseGitStatus(index: Character, workTree: Character) -> GitFileStatus {
        // Untracked files
        if index == "?" && workTree == "?" {
            return .untracked
        }

        // Ignored files
        if index == "!" && workTree == "!" {
            return .ignored
        }

        // Unmerged (conflict)
        if index == "U" || workTree == "U" ||
           (index == "A" && workTree == "A") ||
           (index == "D" && workTree == "D") {
            return .unmerged
        }

        // Check work tree status first (unstaged changes)
        switch workTree {
        case "M": return .modified
        case "D": return .deleted
        default: break
        }

        // Check index status (staged changes)
        switch index {
        case "M": return .staged
        case "A": return .added
        case "D": return .stagedDeleted
        case "R": return .renamed
        case "C": return .copied
        default: break
        }

        return .clean
    }

    // MARK: - Staging Operations

    /// Stage files for commit
    func stageFiles(_ urls: [URL], in repoURL: URL) -> Bool {
        let paths = urls.map { $0.path }
        let result = runGitCommand(["add"] + paths, in: repoURL)
        return result.exitCode == 0
    }

    /// Stage all changes
    func stageAll(in repoURL: URL) -> Bool {
        let result = runGitCommand(["add", "-A"], in: repoURL)
        return result.exitCode == 0
    }

    /// Unstage files
    func unstageFiles(_ urls: [URL], in repoURL: URL) -> Bool {
        let paths = urls.map { $0.path }
        let result = runGitCommand(["reset", "HEAD"] + paths, in: repoURL)
        return result.exitCode == 0
    }

    /// Unstage all files
    func unstageAll(in repoURL: URL) -> Bool {
        let result = runGitCommand(["reset", "HEAD"], in: repoURL)
        return result.exitCode == 0
    }

    /// Discard changes to files (restore to HEAD)
    func discardChanges(_ urls: [URL], in repoURL: URL) -> Bool {
        let paths = urls.map { $0.path }
        let result = runGitCommand(["checkout", "--"] + paths, in: repoURL)
        return result.exitCode == 0
    }

    // MARK: - Commit Operations

    /// Check if commit signing is enabled in git config
    private func isCommitSigningEnabled(in repoURL: URL) -> Bool {
        let result = runGitCommand(["config", "--get", "commit.gpgsign"], in: repoURL)
        guard let output = result.output?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            return false
        }
        return output.lowercased() == "true"
    }

    /// Get the GPG format (openpgp or ssh)
    private func getGPGFormat(in repoURL: URL) -> String {
        let result = runGitCommand(["config", "--get", "gpg.format"], in: repoURL)
        return result.output?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "openpgp"
    }

    /// Commit staged changes with message
    func commit(message: String, in repoURL: URL) -> (success: Bool, error: String?) {
        var args = ["commit", "-m", message]

        // Check if signing is enabled in git config
        let shouldSign = isCommitSigningEnabled(in: repoURL)
        if shouldSign {
            args.insert("-S", at: 1)  // Add -S flag for signing
        }

        // First attempt: try with signing if enabled
        let result = runGitCommand(args, in: repoURL)

        if result.exitCode == 0 {
            return (true, nil)
        } else if shouldSign {
            // Signing failed - attempt fallback to unsigned commit
            let gpgFormat = getGPGFormat(in: repoURL)
            let signingError = result.error ?? "Unknown signing error"

            // Check if it's a signing-related error
            let isSigningError = signingError.lowercased().contains("gpg") ||
                                signingError.lowercased().contains("signing") ||
                                signingError.lowercased().contains("secret key") ||
                                signingError.lowercased().contains("ssh")

            if isSigningError {
                // Return detailed error about signing failure with fallback option
                let errorMessage = """
                Commit signing failed (\(gpgFormat == "ssh" ? "SSH" : "GPG")): \(signingError)

                To fix this issue:
                • For GPG: Verify your signing key is configured (git config user.signingkey)
                • For SSH: Ensure your SSH key is available and allowed for signing
                • Or disable signing temporarily: git config --local commit.gpgsign false

                Attempting unsigned commit as fallback...
                """

                // Try again without signing as fallback
                let fallbackArgs = ["commit", "-m", message, "--no-gpg-sign"]
                let fallbackResult = runGitCommand(fallbackArgs, in: repoURL)

                if fallbackResult.exitCode == 0 {
                    return (true, errorMessage + "\n\n✓ Unsigned commit succeeded.")
                } else {
                    return (false, errorMessage + "\n\n✗ Unsigned commit also failed: \(fallbackResult.error ?? "Unknown error")")
                }
            } else {
                // Not a signing error, return original error
                return (false, result.error ?? "Commit failed")
            }
        } else {
            // Signing not enabled and commit failed
            return (false, result.error ?? "Commit failed")
        }
    }

    // MARK: - Remote Operations

    /// Push to remote
    func push(in repoURL: URL) -> (success: Bool, error: String?, alreadyUpToDate: Bool) {
        // First attempt: normal push
        let result = runGitCommand(["push"], in: repoURL)

        // Check for "already up to date" in stderr (git sends info messages to stderr)
        let stderr = result.error?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let isUpToDate = stderr.lowercased().contains("everything up-to-date")

        if result.exitCode == 0 {
            return (true, nil, isUpToDate)
        }

        // Check for "no upstream branch" error - attempt auto-publish
        if isNoUpstreamError(stderr) {
            print("🔄 [GitService] No upstream branch detected, attempting auto-publish...")

            // Get current branch name
            guard let branch = getCurrentBranch(for: repoURL) else {
                print("❌ [GitService] Failed to determine current branch for auto-publish")
                return (false, "Failed to determine current branch. Cannot auto-publish.", false)
            }

            print("📤 [GitService] Auto-publishing branch '\(branch)' to origin...")

            // Retry with upstream tracking
            let retryResult = runGitCommand(["push", "-u", "origin", branch], in: repoURL)

            if retryResult.exitCode == 0 {
                print("✅ [GitService] Auto-publish successful for branch '\(branch)'")
                return (true, nil, false)  // Success via auto-publish
            } else {
                print("❌ [GitService] Auto-publish failed:")
                print("   Exit code: \(retryResult.exitCode)")
                if let error = retryResult.error {
                    print("   Error: \(error)")
                }
                // Auto-publish failed - return formatted error with helpful message
                let errorMsg = formatAutoPublishError(retryResult, branch: branch)
                return (false, errorMsg, false)
            }
        }

        // Other errors - return as-is
        let errorMsg = [result.error, result.output]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        return (false, errorMsg.isEmpty ? "Push failed (exit code \(result.exitCode))" : errorMsg, false)
    }

    /// Check if error indicates missing upstream branch
    private func isNoUpstreamError(_ error: String) -> Bool {
        let lowercased = error.lowercased()
        return lowercased.contains("no upstream") ||
               lowercased.contains("has no upstream branch")
    }

    /// Format detailed error message for auto-publish failures
    private func formatAutoPublishError(_ result: GitResult, branch: String) -> String {
        let baseError = result.error ?? "Unknown error"
        let lowercased = baseError.lowercased()

        if lowercased.contains("remote origin does not exist") ||
           lowercased.contains("does not appear to be a git repository") {
            return """
            Failed to publish branch '\(branch)': No remote named 'origin' is configured.

            To fix:
            • Add remote: git remote add origin <url>
            • Or push to different remote: git push -u <remote> \(branch)
            """
        } else if lowercased.contains("permission denied") ||
                  lowercased.contains("authentication failed") {
            return """
            Failed to publish branch '\(branch)': Permission denied.

            To fix:
            • Verify SSH/HTTPS credentials are configured
            • Check repository access permissions
            • Try: git config credential.helper store
            """
        } else if lowercased.contains("could not resolve host") ||
                  lowercased.contains("network is unreachable") {
            return """
            Failed to publish branch '\(branch)': Network error.

            \(baseError)

            Check your internet connection and try again.
            """
        } else {
            return """
            Failed to publish new branch '\(branch)' to origin:

            \(baseError)
            """
        }
    }

    /// Pull from remote
    func pull(in repoURL: URL) -> (success: Bool, error: String?) {
        let result = runGitCommand(["pull"], in: repoURL)

        if result.exitCode == 0 {
            return (true, nil)
        } else {
            // Include both stdout and stderr in error message for debugging
            let errorMsg = [result.error, result.output]
                .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .joined(separator: " ")
            return (false, errorMsg.isEmpty ? "Pull failed (exit code \(result.exitCode))" : errorMsg)
        }
    }

    /// Check if there are unpushed commits
    func hasUnpushedCommits(in repoURL: URL) -> Bool {
        let result = runGitCommand(["log", "@{u}..", "--oneline"], in: repoURL)
        guard let output = result.output, result.exitCode == 0 else {
            return false
        }
        return !output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Check if there are commits to pull
    func hasUnpulledCommits(in repoURL: URL) -> Bool {
        // First fetch to update remote refs
        _ = runGitCommand(["fetch"], in: repoURL)

        let result = runGitCommand(["log", "..@{u}", "--oneline"], in: repoURL)
        guard let output = result.output, result.exitCode == 0 else {
            return false
        }
        return !output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Diff Operations

    /// Get diff for a file
    func getDiff(for fileURL: URL, in repoURL: URL, staged: Bool = false) -> String? {
        let relativePath = fileURL.path.replacingOccurrences(of: repoURL.path + "/", with: "")

        guard !relativePath.isEmpty else {
            print("GitService.getDiff: Invalid relative path")
            return nil
        }

        var args = ["diff"]
        if staged {
            args.append("--cached")
        }
        args.append(relativePath)

        let result = runGitCommand(args, in: repoURL)

        if result.exitCode != 0 {
            print("GitService.getDiff: git diff failed with exit code \(result.exitCode)")
            if let error = result.error, !error.isEmpty {
                print("GitService.getDiff: \(error)")
            }
        }

        return result.output
    }

    /// Check if a file is tracked by git
    func isFileTracked(_ fileURL: URL, in repoURL: URL) -> Bool {
        let relativePath = fileURL.path.replacingOccurrences(of: repoURL.path + "/", with: "")
        let result = runGitCommand(["ls-files", relativePath], in: repoURL)
        return !(result.output?.isEmpty ?? true)
    }

    /// Move a file using git mv (preserves history)
    func moveFile(from sourceURL: URL, to destinationURL: URL, in repoURL: URL) -> Bool {
        let sourcePath = sourceURL.path.replacingOccurrences(of: repoURL.path + "/", with: "")
        let destPath = destinationURL.path.replacingOccurrences(of: repoURL.path + "/", with: "")

        let result = runGitCommand(["mv", sourcePath, destPath], in: repoURL)
        return result.exitCode == 0
    }

    // MARK: - Commit History Operations

    /// Get commit log with pagination
    func getCommitLog(for repoURL: URL, limit: Int = 100, offset: Int = 0) -> [GitCommit] {
        // Format: hash|short_hash|author|email|timestamp|subject
        let format = "%H|%h|%an|%ae|%at|%s"
        let args = ["log", "--format=\(format)", "--skip=\(offset)", "-n", "\(limit)"]

        let result = runGitCommand(args, in: repoURL)
        guard let output = result.output, result.exitCode == 0 else {
            return []
        }

        var commits: [GitCommit] = []
        let lines = output.components(separatedBy: .newlines).filter { !$0.isEmpty }

        for line in lines {
            let components = line.components(separatedBy: "|")
            guard components.count >= 6 else { continue }

            let hash = components[0]
            let shortHash = components[1]
            let author = components[2]
            let email = components[3]
            let timestamp = TimeInterval(components[4]) ?? 0
            let message = components[5...].joined(separator: "|") // Handle messages with |

            let commit = GitCommit(
                hash: hash,
                shortHash: shortHash,
                author: author,
                email: email,
                date: Date(timeIntervalSince1970: timestamp),
                message: message
            )
            commits.append(commit)
        }

        return commits
    }

    /// Get diff for a specific commit
    func getCommitDiff(hash: String, in repoURL: URL) -> String? {
        let result = runGitCommand(["show", hash], in: repoURL)
        return result.output
    }

    /// Get list of files changed in a commit
    func getCommitFiles(hash: String, in repoURL: URL) -> [String] {
        let result = runGitCommand(["diff-tree", "--no-commit-id", "--name-only", "-r", hash], in: repoURL)
        guard let output = result.output, result.exitCode == 0 else {
            return []
        }
        return output.components(separatedBy: .newlines)
            .filter { !$0.isEmpty }
    }

    // MARK: - Git Command Execution

    private struct GitResult {
        let output: String?
        let error: String?
        let exitCode: Int32
    }

    private func runGitCommand(_ arguments: [String], in directory: URL) -> GitResult {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = arguments
        process.currentDirectoryURL = directory

        // Set GIT_DIR and GIT_WORK_TREE to help git find .git in sandboxed environment
        var env = ProcessInfo.processInfo.environment
        env["GIT_DIR"] = directory.appendingPathComponent(".git").path
        env["GIT_WORK_TREE"] = directory.path
        process.environment = env

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        do {
            try process.run()
            process.waitUntilExit()

            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

            let output = String(data: outputData, encoding: .utf8)
            let error = String(data: errorData, encoding: .utf8)

            return GitResult(output: output, error: error, exitCode: process.terminationStatus)
        } catch {
            return GitResult(output: nil, error: error.localizedDescription, exitCode: -1)
        }
    }
}
