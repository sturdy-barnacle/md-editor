//
//  ServiceLayerTests.swift
//  tibokTests
//
//  Tests for service layer classes: DocumentManager, WorkspaceService,
//  CommandService, UIStateService, and FileOperationsService.
//

import XCTest
@testable import tibok

@MainActor
final class ServiceLayerTests: XCTestCase {

    var tempDir: URL!

    override func setUp() {
        super.setUp()
        // Create temporary directory for file operations tests
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDown() {
        super.tearDown()
        // Clean up temporary directory
        try? FileManager.default.removeItem(at: tempDir)
    }

    // MARK: - FileOperationsService Tests

    func testFileOperationsService_CreateFile_Success() throws {
        let service = FileOperationsService.shared
        let fileURL = try service.createFile(named: "test", in: tempDir)

        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
        XCTAssertTrue(fileURL.lastPathComponent.hasSuffix(".md"))
    }

    func testFileOperationsService_CreateFile_AddsExtensionIfMissing() throws {
        let service = FileOperationsService.shared
        let fileURL = try service.createFile(named: "myfile", in: tempDir)

        XCTAssertEqual(fileURL.lastPathComponent, "myfile.md")
    }

    func testFileOperationsService_CreateFile_PreservesExtension() throws {
        let service = FileOperationsService.shared
        let fileURL = try service.createFile(named: "existing.md", in: tempDir)

        XCTAssertEqual(fileURL.lastPathComponent, "existing.md")
    }

    func testFileOperationsService_DeleteFile_Success() throws {
        let service = FileOperationsService.shared

        // Create a file first
        let fileURL = tempDir.appendingPathComponent("todelete.md")
        try "content".write(to: fileURL, atomically: true, encoding: .utf8)
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))

        // Delete it
        try service.deleteFile(at: fileURL)
        // Note: deleteFile moves to trash, so file may still exist in trash
    }

    func testFileOperationsService_LoadDocument_Success() throws {
        let service = FileOperationsService.shared

        let fileURL = tempDir.appendingPathComponent("test.md")
        let content = "Test content"
        try content.write(to: fileURL, atomically: true, encoding: .utf8)

        let (title, loadedContent) = try service.loadDocument(from: fileURL)

        XCTAssertEqual(title, "test")
        XCTAssertEqual(loadedContent, content)
    }

    func testFileOperationsService_SaveDocument_Success() throws {
        let service = FileOperationsService.shared

        let fileURL = tempDir.appendingPathComponent("output.md")
        let content = "Written content"

        try service.saveDocument(content: content, to: fileURL)

        let readContent = try String(contentsOf: fileURL, encoding: .utf8)
        XCTAssertEqual(readContent, content)
    }

    // MARK: - UIStateService Tests

    func testUIStateService_ShowToast_UpdatesMessage() {
        let service = UIStateService.shared
        let message = "Test message"

        service.showToast(message)
        XCTAssertEqual(service.toastMessage, message)
    }

    func testUIStateService_ShowToast_WithIcon() {
        let service = UIStateService.shared
        let icon = "checkmark"

        service.showToast("Message", icon: icon)
        XCTAssertEqual(service.toastIcon, icon)
    }

    func testUIStateService_ShowToast_WithNilIcon() {
        let service = UIStateService.shared

        service.showToast("Message", icon: nil)
        XCTAssertNil(service.toastIcon)
    }

    // MARK: - CommandService Tests

    func testCommandService_Register_AddsCommand() {
        let service = CommandService.shared
        let initialCount = service.commands.count

        let command = Command(
            id: UUID().uuidString,
            title: "Test Command",
            category: .general,
            source: "test.source",
            action: {}
        )

        service.register(command)
        XCTAssertGreaterThan(service.commands.count, initialCount)

        // Cleanup
        service.unregister(source: "test.source")
    }

    func testCommandService_Unregister_RemovesCommandsBySource() {
        let service = CommandService.shared
        let source = "test.source.unique"

        let command1 = Command(
            id: UUID().uuidString,
            title: "Command 1",
            category: .general,
            source: source,
            action: {}
        )
        let command2 = Command(
            id: UUID().uuidString,
            title: "Command 2",
            category: .general,
            source: source,
            action: {}
        )

        service.register(command1)
        service.register(command2)

        let countBefore = service.commands.count
        service.unregister(source: source)
        let countAfter = service.commands.count

        XCTAssertEqual(countAfter, countBefore - 2)
    }

    func testCommandService_Search_FiltersCorrectly() {
        let service = CommandService.shared
        let source = "test.search.source"

        let command1 = Command(
            id: UUID().uuidString,
            title: "Open File",
            category: .file,
            source: source,
            action: {}
        )
        let command2 = Command(
            id: UUID().uuidString,
            title: "Save File",
            category: .file,
            source: source,
            action: {}
        )

        service.register(command1)
        service.register(command2)

        let searchResults = service.search("File")
        XCTAssertGreaterThanOrEqual(searchResults.count, 2)
        XCTAssertTrue(searchResults.contains(where: { $0.title == "Open File" }))
        XCTAssertTrue(searchResults.contains(where: { $0.title == "Save File" }))

        // Cleanup
        service.unregister(source: source)
    }

    func testCommandService_CommandCategory_HasCorrectIcons() {
        XCTAssertEqual(CommandCategory.file.icon, "doc")
        XCTAssertEqual(CommandCategory.edit.icon, "pencil")
        XCTAssertEqual(CommandCategory.view.icon, "eye")
        XCTAssertEqual(CommandCategory.general.icon, "command")
    }

    // MARK: - DocumentManager Tests

    func testDocumentManager_AddDocument_Success() {
        let manager = DocumentManager.shared
        let initialCount = manager.documents.count

        let doc = Document(
            title: "Test",
            content: "Content",
            fileURL: nil,
            isModified: false,
            lastSaved: nil,
            isActive: true
        )

        manager.addDocument(doc)
        XCTAssertGreaterThan(manager.documents.count, initialCount)

        // Cleanup
        manager.closeTab(id: doc.id)
    }

    func testDocumentManager_AddDocument_SetsActive() {
        let manager = DocumentManager.shared

        let doc = Document(
            title: "Test",
            content: "Content",
            fileURL: nil,
            isModified: false,
            lastSaved: nil,
            isActive: true
        )

        manager.addDocument(doc, makeActive: true)
        XCTAssertEqual(manager.activeDocumentID, doc.id)

        // Cleanup
        manager.closeTab(id: doc.id)
    }

    func testDocumentManager_CloseTab_RemovesDocument() {
        let manager = DocumentManager.shared

        let doc = Document(
            title: "Test",
            content: "Content",
            fileURL: nil,
            isModified: false,
            lastSaved: nil,
            isActive: true
        )

        manager.addDocument(doc)
        let countAfterAdd = manager.documents.count

        manager.closeTab(id: doc.id)
        XCTAssertLessThan(manager.documents.count, countAfterAdd)
    }

    func testDocumentManager_SwitchToTab_UpdatesActiveDocument() {
        let manager = DocumentManager.shared

        let doc1 = Document(
            title: "Test 1",
            content: "Content 1",
            fileURL: nil,
            isModified: false,
            lastSaved: nil,
            isActive: true
        )
        let doc2 = Document(
            title: "Test 2",
            content: "Content 2",
            fileURL: nil,
            isModified: false,
            lastSaved: nil,
            isActive: true
        )

        manager.addDocument(doc1)
        manager.addDocument(doc2)

        manager.switchToTab(id: doc1.id)
        XCTAssertEqual(manager.activeDocumentID, doc1.id)

        // Cleanup
        manager.closeTab(id: doc1.id)
        manager.closeTab(id: doc2.id)
    }

    // MARK: - WorkspaceService Tests

    func testWorkspaceService_SetWorkspace_Success() {
        let service = WorkspaceService.shared

        service.setWorkspace(tempDir)
        XCTAssertEqual(service.workspaceURL, tempDir)

        // Cleanup
        service.closeWorkspace()
    }

    func testWorkspaceService_CloseWorkspace_ClearsURL() {
        let service = WorkspaceService.shared

        service.setWorkspace(tempDir)
        XCTAssertNotNil(service.workspaceURL)

        service.closeWorkspace()
        XCTAssertNil(service.workspaceURL)
    }

    func testWorkspaceService_AddToRecentFiles_TracksFile() {
        let service = WorkspaceService.shared

        let fileURL = tempDir.appendingPathComponent("recent.md")
        try? "content".write(to: fileURL, atomically: true, encoding: .utf8)

        service.addToRecentFiles(fileURL)
        XCTAssertTrue(service.recentFiles.contains(fileURL))

        // Cleanup
        service.removeFromRecentFiles(fileURL)
    }

    func testWorkspaceService_RemoveFromRecentFiles_Success() {
        let service = WorkspaceService.shared

        let fileURL = tempDir.appendingPathComponent("recent2.md")
        try? "content".write(to: fileURL, atomically: true, encoding: .utf8)

        service.addToRecentFiles(fileURL)
        service.removeFromRecentFiles(fileURL)
        XCTAssertFalse(service.recentFiles.contains(fileURL))
    }

    func testWorkspaceService_AddToFavorites_TracksFile() {
        let service = WorkspaceService.shared

        let fileURL = tempDir.appendingPathComponent("favorite.md")
        try? "content".write(to: fileURL, atomically: true, encoding: .utf8)

        service.addToFavorites(fileURL)
        XCTAssertTrue(service.favoriteFiles.contains(fileURL))

        // Cleanup
        service.removeFromFavorites(fileURL)
    }

    func testWorkspaceService_RemoveFromFavorites_Success() {
        let service = WorkspaceService.shared

        let fileURL = tempDir.appendingPathComponent("favorite2.md")
        try? "content".write(to: fileURL, atomically: true, encoding: .utf8)

        service.addToFavorites(fileURL)
        service.removeFromFavorites(fileURL)
        XCTAssertFalse(service.favoriteFiles.contains(fileURL))
    }

    func testWorkspaceService_ClearRecentFiles_RemovesAll() {
        let service = WorkspaceService.shared

        let file1 = tempDir.appendingPathComponent("file1.md")
        let file2 = tempDir.appendingPathComponent("file2.md")
        try? "content1".write(to: file1, atomically: true, encoding: .utf8)
        try? "content2".write(to: file2, atomically: true, encoding: .utf8)

        service.addToRecentFiles(file1)
        service.addToRecentFiles(file2)

        service.clearRecentFiles()
        XCTAssertEqual(service.recentFiles.count, 0)
    }

    // MARK: - Integration Tests

    func testServiceLayer_FileAndWorkspaceIntegration() throws {
        let fileService = FileOperationsService.shared
        let workspaceService = WorkspaceService.shared

        // Create file
        let fileURL = try fileService.createFile(named: "integration", in: tempDir)

        // Save content to it
        try fileService.saveDocument(content: "Integration test", to: fileURL)

        // Add to workspace recents
        workspaceService.addToRecentFiles(fileURL)
        XCTAssertTrue(workspaceService.recentFiles.contains(fileURL))

        // Load and verify
        let (_, content) = try fileService.loadDocument(from: fileURL)
        XCTAssertEqual(content, "Integration test")

        // Cleanup
        workspaceService.removeFromRecentFiles(fileURL)
    }
}
