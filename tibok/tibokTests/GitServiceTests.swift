//
//  GitServiceTests.swift
//  tibokTests
//
//  Comprehensive tests for GitService - repository detection, branch operations,
//  staging/unstaging, committing, pushing, pulling, and diff operations.
//

import XCTest
@testable import tibok

final class GitServiceTests: XCTestCase {

    var gitService: GitService!
    var tempRepoURL: URL!
    var tempDir: URL!

    override func setUp() {
        super.setUp()
        gitService = GitService.shared

        // Create temporary directory for test repository
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        tempRepoURL = tempDir
    }

    override func tearDown() {
        super.tearDown()
        // Clean up temporary directory
        try? FileManager.default.removeItem(at: tempDir)
    }

    // MARK: - Helper Methods

    /// Initialize a git repository at tempRepoURL
    private func initializeRepository() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["init"]
        process.currentDirectoryURL = tempRepoURL
        try? process.run()
        process.waitUntilExit()
    }

    /// Configure git user for commits
    private func configureGitUser() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["config", "user.email", "test@example.com"]
        process.currentDirectoryURL = tempRepoURL
        try? process.run()
        process.waitUntilExit()

        let process2 = Process()
        process2.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process2.arguments = ["config", "user.name", "Test User"]
        process2.currentDirectoryURL = tempRepoURL
        try? process2.run()
        process2.waitUntilExit()
    }

    /// Create a test file and commit it
    private func createAndCommitFile(name: String, content: String = "test content") {
        let fileURL = tempRepoURL.appendingPathComponent(name)
        try? content.write(to: fileURL, atomically: true, encoding: .utf8)

        let addProcess = Process()
        addProcess.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        addProcess.arguments = ["add", name]
        addProcess.currentDirectoryURL = tempRepoURL
        try? addProcess.run()
        addProcess.waitUntilExit()

        let commitProcess = Process()
        commitProcess.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        commitProcess.arguments = ["commit", "-m", "Initial commit"]
        commitProcess.currentDirectoryURL = tempRepoURL
        try? commitProcess.run()
        commitProcess.waitUntilExit()
    }

    // MARK: - Repository Detection Tests

    func testIsGitRepository_NonGitDirectory_ReturnsFalse() {
        XCTAssertFalse(gitService.isGitRepository(at: tempRepoURL))
    }

    func testIsGitRepository_GitDirectory_ReturnsTrue() {
        initializeRepository()
        XCTAssertTrue(gitService.isGitRepository(at: tempRepoURL))
    }

    func testGetRepositoryRoot_NonGitDirectory_ReturnsNil() {
        let root = gitService.getRepositoryRoot(for: tempRepoURL)
        XCTAssertNil(root)
    }

    func testGetRepositoryRoot_GitDirectory_ReturnsRootPath() {
        initializeRepository()
        let root = gitService.getRepositoryRoot(for: tempRepoURL)
        XCTAssertNotNil(root)
        XCTAssertEqual(root?.lastPathComponent, tempRepoURL.lastPathComponent)
    }

    // MARK: - Branch Operations Tests

    func testGetCurrentBranch_NewRepository_ReturnsMaster() {
        initializeRepository()
        let branch = gitService.getCurrentBranch(for: tempRepoURL)
        // Git initializes with 'master' or 'main' depending on version
        XCTAssertNotNil(branch)
        XCTAssert(branch == "master" || branch == "main")
    }

    func testGetBranches_NewRepository_ReturnsCurrentBranch() {
        initializeRepository()
        configureGitUser()
        createAndCommitFile(name: "README.md")

        let branches = gitService.getBranches(for: tempRepoURL)
        XCTAssertTrue(branches.count > 0)
        XCTAssert(branches.contains(where: { $0 == "master" || $0 == "main" }))
    }

    func testCheckout_ValidBranch_Succeeds() {
        initializeRepository()
        configureGitUser()
        createAndCommitFile(name: "README.md")

        // Create a new branch
        let createProcess = Process()
        createProcess.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        createProcess.arguments = ["branch", "feature"]
        createProcess.currentDirectoryURL = tempRepoURL
        try? createProcess.run()
        createProcess.waitUntilExit()

        // Checkout the branch
        let success = gitService.checkout(branch: "feature", in: tempRepoURL)
        XCTAssertTrue(success)

        let currentBranch = gitService.getCurrentBranch(for: tempRepoURL)
        XCTAssertEqual(currentBranch, "feature")
    }

    func testCheckout_InvalidBranch_Fails() {
        initializeRepository()
        configureGitUser()
        createAndCommitFile(name: "README.md")

        let success = gitService.checkout(branch: "nonexistent-branch", in: tempRepoURL)
        XCTAssertFalse(success)
    }

    // MARK: - File Status Tests

    func testGetChangedFiles_NoChanges_ReturnsEmpty() {
        initializeRepository()
        configureGitUser()
        createAndCommitFile(name: "README.md")

        let files = gitService.getChangedFiles(for: tempRepoURL)
        XCTAssertTrue(files.isEmpty)
    }

    func testGetChangedFiles_NewUntrackedFile_ReturnsFile() {
        initializeRepository()
        configureGitUser()
        createAndCommitFile(name: "README.md")

        let newFileURL = tempRepoURL.appendingPathComponent("test.md")
        try? "new content".write(to: newFileURL, atomically: true, encoding: .utf8)

        let files = gitService.getChangedFiles(for: tempRepoURL)
        XCTAssertTrue(files.contains(where: { $0.filename == "test.md" }))
    }

    func testGetChangedFiles_ModifiedFile_ReturnsModified() {
        initializeRepository()
        configureGitUser()
        createAndCommitFile(name: "README.md", content: "original")

        let readmeURL = tempRepoURL.appendingPathComponent("README.md")
        try? "modified content".write(to: readmeURL, atomically: true, encoding: .utf8)

        let files = gitService.getChangedFiles(for: tempRepoURL)
        let modified = files.first(where: { $0.filename == "README.md" && !$0.isStaged })
        XCTAssertNotNil(modified)
        XCTAssert(modified?.status == .modified || modified?.status == .untracked)
    }

    func testGetFileStatus_UntrackedFile_ReturnsUntracked() {
        initializeRepository()
        configureGitUser()
        createAndCommitFile(name: "README.md")

        let newFileURL = tempRepoURL.appendingPathComponent("test.md")
        try? "test".write(to: newFileURL, atomically: true, encoding: .utf8)

        let status = gitService.getFileStatus(for: newFileURL, in: tempRepoURL)
        XCTAssertEqual(status, .untracked)
    }

    // MARK: - Staging Tests

    func testStageFiles_UntrackedFile_Succeeds() {
        initializeRepository()
        configureGitUser()
        createAndCommitFile(name: "README.md")

        let newFileURL = tempRepoURL.appendingPathComponent("test.md")
        try? "test content".write(to: newFileURL, atomically: true, encoding: .utf8)

        let success = gitService.stageFiles([newFileURL], in: tempRepoURL)
        XCTAssertTrue(success)

        let files = gitService.getChangedFiles(for: tempRepoURL)
        let staged = files.first(where: { $0.filename == "test.md" && $0.isStaged })
        XCTAssertNotNil(staged)
    }

    func testStageAll_MultipleUntrackedFiles_Succeeds() {
        initializeRepository()
        configureGitUser()
        createAndCommitFile(name: "README.md")

        try? "content1".write(to: tempRepoURL.appendingPathComponent("test1.md"), atomically: true, encoding: .utf8)
        try? "content2".write(to: tempRepoURL.appendingPathComponent("test2.md"), atomically: true, encoding: .utf8)

        let success = gitService.stageAll(in: tempRepoURL)
        XCTAssertTrue(success)

        let files = gitService.getChangedFiles(for: tempRepoURL)
        XCTAssertTrue(files.allSatisfy { $0.isStaged })
    }

    func testUnstageFiles_StagedFile_Succeeds() {
        initializeRepository()
        configureGitUser()
        createAndCommitFile(name: "README.md")

        let newFileURL = tempRepoURL.appendingPathComponent("test.md")
        try? "test content".write(to: newFileURL, atomically: true, encoding: .utf8)

        gitService.stageFiles([newFileURL], in: tempRepoURL)

        let success = gitService.unstageFiles([newFileURL], in: tempRepoURL)
        XCTAssertTrue(success)

        let files = gitService.getChangedFiles(for: tempRepoURL)
        let unstaged = files.first(where: { $0.filename == "test.md" && !$0.isStaged })
        XCTAssertNotNil(unstaged)
    }

    // MARK: - Commit Tests

    func testCommit_StagedFiles_Succeeds() {
        initializeRepository()
        configureGitUser()
        createAndCommitFile(name: "README.md")

        let newFileURL = tempRepoURL.appendingPathComponent("test.md")
        try? "test content".write(to: newFileURL, atomically: true, encoding: .utf8)

        gitService.stageFiles([newFileURL], in: tempRepoURL)

        let result = gitService.commit(message: "Add test file", in: tempRepoURL)
        XCTAssertTrue(result.success)
        XCTAssertNil(result.error)
    }

    func testCommit_EmptyMessage_Fails() {
        initializeRepository()
        configureGitUser()
        createAndCommitFile(name: "README.md")

        let newFileURL = tempRepoURL.appendingPathComponent("test.md")
        try? "test content".write(to: newFileURL, atomically: true, encoding: .utf8)

        gitService.stageFiles([newFileURL], in: tempRepoURL)

        let result = gitService.commit(message: "", in: tempRepoURL)
        XCTAssertFalse(result.success)
    }

    // MARK: - Diff Tests

    func testGetDiff_UnstagedChanges_ReturnsDiff() {
        initializeRepository()
        configureGitUser()
        createAndCommitFile(name: "README.md", content: "original content")

        let readmeURL = tempRepoURL.appendingPathComponent("README.md")
        try? "modified content".write(to: readmeURL, atomically: true, encoding: .utf8)

        let diff = gitService.getDiff(for: readmeURL, in: tempRepoURL, staged: false)
        XCTAssertNotNil(diff)
        XCTAssertTrue(diff?.contains("original content") ?? false)
        XCTAssertTrue(diff?.contains("modified content") ?? false)
    }

    func testGetDiff_NoChanges_ReturnsEmpty() {
        initializeRepository()
        configureGitUser()
        createAndCommitFile(name: "README.md")

        let readmeURL = tempRepoURL.appendingPathComponent("README.md")

        let diff = gitService.getDiff(for: readmeURL, in: tempRepoURL, staged: false)
        XCTAssertNotNil(diff)
        XCTAssertTrue(diff?.isEmpty ?? true)
    }

    // MARK: - Unpushed/Unpulled Commits Tests

    func testHasUnpushedCommits_NewRepository_ReturnsFalse() {
        initializeRepository()
        configureGitUser()
        createAndCommitFile(name: "README.md")

        // Without a remote configured, this should return false
        let hasUnpushed = gitService.hasUnpushedCommits(in: tempRepoURL)
        XCTAssertFalse(hasUnpushed)
    }

    func testHasUnpulledCommits_NewRepository_ReturnsFalse() {
        initializeRepository()
        configureGitUser()
        createAndCommitFile(name: "README.md")

        // Without a remote configured, this should return false
        let hasUnpulled = gitService.hasUnpulledCommits(in: tempRepoURL)
        XCTAssertFalse(hasUnpulled)
    }

    // MARK: - File Status Enumeration Tests

    func testGitFileStatus_Colors() {
        XCTAssertEqual(GitFileStatus.modified.color, "blue")
        XCTAssertEqual(GitFileStatus.added.color, "green")
        XCTAssertEqual(GitFileStatus.untracked.color, "yellow")
        XCTAssertEqual(GitFileStatus.unmerged.color, "red")
        XCTAssertEqual(GitFileStatus.deleted.color, "gray")
    }

    func testGitFileStatus_IsStaged() {
        XCTAssertTrue(GitFileStatus.added.isStaged)
        XCTAssertTrue(GitFileStatus.staged.isStaged)
        XCTAssertTrue(GitFileStatus.stagedDeleted.isStaged)
        XCTAssertFalse(GitFileStatus.modified.isStaged)
        XCTAssertFalse(GitFileStatus.untracked.isStaged)
    }
}
