//
//  KeyboardShortcuts.swift
//  tibok
//
//  Keyboard shortcut notification names
//

import Foundation

extension Notification.Name {
    // Git operations
    static let gitCommit = Notification.Name("gitCommit")
    static let gitPush = Notification.Name("gitPush")
    static let gitPull = Notification.Name("gitPull")
    static let gitSwitchBranch = Notification.Name("gitSwitchBranch")
    static let gitHistory = Notification.Name("gitHistory")
    static let gitRefreshStatus = Notification.Name("gitRefreshStatus")

    // Workspace operations
    static let newWorkspaceFile = Notification.Name("newWorkspaceFile")
    static let newWorkspaceFolder = Notification.Name("newWorkspaceFolder")
    static let deleteSelection = Notification.Name("deleteSelection")
    static let renameSelection = Notification.Name("renameSelection")
}
