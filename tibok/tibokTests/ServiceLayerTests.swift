//
//  ServiceLayerTests.swift
//  tibokTests
//
//  Comprehensive tests for service layer classes: DocumentManager, WorkspaceService,
//  CommandService, UIStateService, and FileOperationsService.
//

import XCTest
@testable import tibok

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

    func testFileOperationsService_ReadFile_Success() {
        let fileURL = tempDir.appendingPathComponent("test.md")
        let content = "Test content"
        try? content.write(to: fileURL, atomically: true, encoding: .utf8)

        let result = FileOperationsService.readFile(at: fileURL)
        XCTAssertEqual(result, content)
    }

    func testFileOperationsService_ReadFile_NonexistentFile_ReturnsNil() {
        let fileURL = tempDir.appendingPathComponent("nonexistent.md")
        let result = FileOperationsService.readFile(at: fileURL)
        XCTAssertNil(result)
    }

    func testFileOperationsService_WriteFile_Success() {
        let fileURL = tempDir.appendingPathComponent("output.md")
        let content = "Written content"

        let success = FileOperationsService.writeFile(content, to: fileURL)
        XCTAssertTrue(success)

        let readContent = try? String(contentsOf: fileURL, encoding: .utf8)
        XCTAssertEqual(readContent, content)
    }

    func testFileOperationsService_FileExists_ExistingFile_ReturnsTrue() {
        let fileURL = tempDir.appendingPathComponent("existing.md")
        try? "content".write(to: fileURL, atomically: true, encoding: .utf8)

        let exists = FileOperationsService.fileExists(at: fileURL)
        XCTAssertTrue(exists)
    }

    func testFileOperationsService_FileExists_NonexistentFile_ReturnsFalse() {
        let fileURL = tempDir.appendingPathComponent("nonexistent.md")
        let exists = FileOperationsService.fileExists(at: fileURL)
        XCTAssertFalse(exists)
    }

    func testFileOperationsService_CreateDirectory_Success() {
        let dirURL = tempDir.appendingPathComponent("newdir")
        let success = FileOperationsService.createDirectory(at: dirURL)
        XCTAssertTrue(success)

        var isDir: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: dirURL.path, isDirectory: &isDir)
        XCTAssertTrue(exists && isDir.boolValue)
    }

    func testFileOperationsService_DeleteFile_Success() {
        let fileURL = tempDir.appendingPathComponent("todelete.md")
        try? "content".write(to: fileURL, atomically: true, encoding: .utf8)
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))

        let success = FileOperationsService.deleteFile(at: fileURL)
        XCTAssertTrue(success)
        XCTAssertFalse(FileManager.default.fileExists(atPath: fileURL.path))
    }

    // MARK: - UIStateService Tests

    func testUIStateService_ShowToast_UpdatesState() {
        let service = UIStateService()
        let initialToastCount = service.toasts.count

        service.showToast("Test message", icon: nil, duration: 2)
        XCTAssertEqual(service.toasts.count, initialToastCount + 1)
    }

    func testUIStateService_Toast_HasCorrectMessage() {
        let service = UIStateService()
        let message = "Test message"

        service.showToast(message, icon: nil, duration: 2)
        XCTAssertTrue(service.toasts.last?.message == message)
    }

    func testUIStateService_Toast_HasCorrectDuration() {
        let service = UIStateService()
        let duration: TimeInterval = 3.0

        service.showToast("Message", icon: nil, duration: duration)
        XCTAssertEqual(service.toasts.last?.duration, duration)
    }

    func testUIStateService_RemoveToast_RemovesFromList() {
        let service = UIStateService()
        service.showToast("Message 1", icon: nil, duration: 2)
        let toast1 = service.toasts.first
        XCTAssertNotNil(toast1)

        if let toast = toast1 {
            service.removeToast(toast)
            XCTAssertFalse(service.toasts.contains(where: { $0.id == toast.id }))
        }
    }

    // MARK: - CommandService Tests

    func testCommandService_RegisterCommand_Success() {
        let service = CommandService()
        let initialCount = service.allCommands.count

        let command = Command(
            id: UUID().uuidString,
            title: "Test Command",
            category: "Test",
            shortcut: nil,
            action: {}
        )

        service.registerCommand(command, source: "test.source")
        XCTAssertGreater(service.allCommands.count, initialCount)
    }

    func testCommandService_UnregisterCommand_Success() {
        let service = CommandService()
        let commandID = UUID().uuidString
        let command = Command(
            id: commandID,
            title: "Test Command",
            category: "Test",
            shortcut: nil,
            action: {}
        )

        service.registerCommand(command, source: "test.source")
        let countAfterRegister = service.allCommands.count

        service.unregisterCommand(id: commandID)
        XCTAssertLess(service.allCommands.count, countAfterRegister)
    }

    func testCommandService_UnregisterCommandsBySource_RemovesAllFromSource() {
        let service = CommandService()
        let source = "test.source"

        let command1 = Command(
            id: UUID().uuidString,
            title: "Command 1",
            category: "Test",
            shortcut: nil,
            action: {}
        )
        let command2 = Command(
            id: UUID().uuidString,
            title: "Command 2",
            category: "Test",
            shortcut: nil,
            action: {}
        )

        service.registerCommand(command1, source: source)
        service.registerCommand(command2, source: source)

        let countBefore = service.allCommands.count
        service.unregisterCommandsBySource(source)
        let countAfter = service.allCommands.count

        XCTAssertEqual(countAfter, countBefore - 2)
    }

    func testCommandService_SearchCommands_FiltersCorrectly() {
        let service = CommandService()

        let command1 = Command(
            id: UUID().uuidString,
            title: "Open File",
            category: "File",
            shortcut: nil,
            action: {}
        )
        let command2 = Command(
            id: UUID().uuidString,
            title: "Save File",
            category: "File",
            shortcut: nil,
            action: {}
        )
        let command3 = Command(
            id: UUID().uuidString,
            title: "Edit Text",
            category: "Edit",
            shortcut: nil,
            action: {}
        )

        service.registerCommand(command1, source: "test")
        service.registerCommand(command2, source: "test")
        service.registerCommand(command3, source: "test")

        let searchResults = service.searchCommands(query: "File")
        XCTAssertEqual(searchResults.count, 2)
        XCTAssertTrue(searchResults.allSatisfy { $0.title.contains("File") })
    }

    func testCommandService_GetCommandsByCategory_GroupsCorrectly() {
        let service = CommandService()

        let command1 = Command(
            id: UUID().uuidString,
            title: "Open",
            category: "File",
            shortcut: nil,
            action: {}
        )
        let command2 = Command(
            id: UUID().uuidString,
            title: "Save",
            category: "File",
            shortcut: nil,
            action: {}
        )
        let command3 = Command(
            id: UUID().uuidString,
            title: "Undo",
            category: "Edit",
            shortcut: nil,
            action: {}
        )

        service.registerCommand(command1, source: "test")
        service.registerCommand(command2, source: "test")
        service.registerCommand(command3, source: "test")

        let categories = service.groupedByCategory()
        XCTAssertTrue(categories.keys.contains("File"))
        XCTAssertTrue(categories.keys.contains("Edit"))
        XCTAssertEqual(categories["File"]?.count, 2)
        XCTAssertEqual(categories["Edit"]?.count, 1)
    }

    // MARK: - DocumentManager Tests

    func testDocumentManager_CreateDocument_Success() {
        let manager = DocumentManager()
        let initialCount = manager.openDocuments.count

        let docURL = tempDir.appendingPathComponent("test.md")
        try? "content".write(to: docURL, atomically: true, encoding: .utf8)

        manager.openDocument(at: docURL, content: "content")
        XCTAssertGreater(manager.openDocuments.count, initialCount)
    }

    func testDocumentManager_CloseDocument_Success() {
        let manager = DocumentManager()

        let docURL = tempDir.appendingPathComponent("test.md")
        try? "content".write(to: docURL, atomically: true, encoding: .utf8)

        manager.openDocument(at: docURL, content: "content")
        let countAfterOpen = manager.openDocuments.count

        if let doc = manager.openDocuments.first {
            manager.closeDocument(doc)
            XCTAssertLess(manager.openDocuments.count, countAfterOpen)
        }
    }

    func testDocumentManager_ActiveDocument_TracksCurrentDocument() {
        let manager = DocumentManager()

        let docURL1 = tempDir.appendingPathComponent("test1.md")
        let docURL2 = tempDir.appendingPathComponent("test2.md")
        try? "content1".write(to: docURL1, atomically: true, encoding: .utf8)
        try? "content2".write(to: docURL2, atomically: true, encoding: .utf8)

        manager.openDocument(at: docURL1, content: "content1")
        manager.openDocument(at: docURL2, content: "content2")

        if let doc = manager.openDocuments.last {
            manager.setActiveDocument(doc)
            XCTAssertEqual(manager.activeDocument?.url, doc.url)
        }
    }

    // MARK: - WorkspaceService Tests

    func testWorkspaceService_OpenWorkspace_Success() {
        let service = WorkspaceService()

        let success = service.openWorkspace(at: tempDir)
        XCTAssertTrue(success)
        XCTAssertEqual(service.currentWorkspace, tempDir)
    }

    func testWorkspaceService_CloseWorkspace_Success() {
        let service = WorkspaceService()

        service.openWorkspace(at: tempDir)
        XCTAssertNotNil(service.currentWorkspace)

        service.closeWorkspace()
        XCTAssertNil(service.currentWorkspace)
    }

    func testWorkspaceService_AddToRecents_TracksFile() {
        let service = WorkspaceService()

        let fileURL = tempDir.appendingPathComponent("recent.md")
        try? "content".write(to: fileURL, atomically: true, encoding: .utf8)

        service.addToRecents(fileURL)
        XCTAssertTrue(service.recentFiles.contains(fileURL))
    }

    func testWorkspaceService_RemoveFromRecents_Success() {
        let service = WorkspaceService()

        let fileURL = tempDir.appendingPathComponent("recent.md")
        try? "content".write(to: fileURL, atomically: true, encoding: .utf8)

        service.addToRecents(fileURL)
        service.removeFromRecents(fileURL)
        XCTAssertFalse(service.recentFiles.contains(fileURL))
    }

    func testWorkspaceService_AddToFavorites_TracksFile() {
        let service = WorkspaceService()

        let fileURL = tempDir.appendingPathComponent("favorite.md")
        try? "content".write(to: fileURL, atomically: true, encoding: .utf8)

        service.addToFavorites(fileURL)
        XCTAssertTrue(service.favorites.contains(fileURL))
    }

    func testWorkspaceService_RemoveFromFavorites_Success() {
        let service = WorkspaceService()

        let fileURL = tempDir.appendingPathComponent("favorite.md")
        try? "content".write(to: fileURL, atomically: true, encoding: .utf8)

        service.addToFavorites(fileURL)
        service.removeFromFavorites(fileURL)
        XCTAssertFalse(service.favorites.contains(fileURL))
    }

    func testWorkspaceService_ClearRecents_RemovesAll() {
        let service = WorkspaceService()

        let file1 = tempDir.appendingPathComponent("file1.md")
        let file2 = tempDir.appendingPathComponent("file2.md")
        try? "content1".write(to: file1, atomically: true, encoding: .utf8)
        try? "content2".write(to: file2, atomically: true, encoding: .utf8)

        service.addToRecents(file1)
        service.addToRecents(file2)
        XCTAssertGreater(service.recentFiles.count, 0)

        service.clearRecents()
        XCTAssertEqual(service.recentFiles.count, 0)
    }

    // MARK: - Integration Tests

    func testServiceLayer_FileAndWorkspaceIntegration() {
        let fileService = FileOperationsService.self
        let workspaceService = WorkspaceService()

        let fileURL = tempDir.appendingPathComponent("integration.md")
        let content = "Integration test"

        // Write file
        let writeSuccess = fileService.writeFile(content, to: fileURL)
        XCTAssertTrue(writeSuccess)

        // Add to workspace
        workspaceService.addToRecents(fileURL)
        XCTAssertTrue(workspaceService.recentFiles.contains(fileURL))

        // Read file
        let readContent = fileService.readFile(at: fileURL)
        XCTAssertEqual(readContent, content)
    }

    func testServiceLayer_CommandAndUIIntegration() {
        let commandService = CommandService()
        let uiService = UIStateService()

        var commandExecuted = false
        let command = Command(
            id: UUID().uuidString,
            title: "Integration Command",
            category: "Test",
            shortcut: nil,
            action: {
                commandExecuted = true
                uiService.showToast("Command executed", icon: nil, duration: 2)
            }
        )

        commandService.registerCommand(command, source: "test")
        XCTAssertTrue(commandService.allCommands.contains(where: { $0.id == command.id }))
    }
}
