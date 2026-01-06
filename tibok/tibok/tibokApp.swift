//
//  tibokApp.swift
//  tibok
//
//  A native macOS markdown editor built for writers who love simplicity.
//

import SwiftUI
import AppKit
import WebKit

@main
struct tibokApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()
    @AppStorage("appearanceMode") private var appearanceMode: String = AppearanceMode.system.rawValue

    init() {
        // Explicitly register as regular foreground app (not accessory/background app)
        NSApplication.shared.setActivationPolicy(.regular)
    }

    private var windowTitle: String {
        // Empty state - show tagline
        if appState.currentDocument.isEmpty {
            return "tibok — simple markdown editor"
        }

        let filename = appState.currentDocument.fileURL?.lastPathComponent ?? "Untitled"
        let unsavedIndicator: String
        if appState.currentDocument.fileURL == nil {
            unsavedIndicator = " — Edited"
        } else if appState.currentDocument.isModified {
            unsavedIndicator = " •"
        } else {
            unsavedIndicator = ""
        }
        return "tibok — \(filename)\(unsavedIndicator)"
    }

    var body: some Scene {
        WindowGroup(id: "main") {
            MainWindowContent(appState: appState, windowTitle: windowTitle)
                .onAppear {
                    applyAppearance()
                    // Defer plugin initialization to next run loop iteration
                    // This ensures SwiftUI's .sheet() bindings are fully subscribed
                    // before any pendingApprovalRequest is set
                    DispatchQueue.main.async {
                        initializePlugins()
                    }
                    // Ensure app window gets focus when launched
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        NSApplication.shared.activate(ignoringOtherApps: true)
                        if let window = NSApplication.shared.mainWindow {
                            window.makeKeyAndOrderFront(nil)
                        }
                    }
                }
                .onChange(of: appearanceMode) { _, _ in
                    applyAppearance()
                }
        }
        .handlesExternalEvents(matching: ["main"])
        .commands {
            // File menu commands
            CommandGroup(replacing: .newItem) {
                Button("New Document") {
                    appState.createNewDocument()
                }
                .keyboardShortcut("n", modifiers: .command)

                Button("Open...") {
                    appState.openDocument()
                }
                .keyboardShortcut("o", modifiers: .command)

                Button("Open Folder...") {
                    appState.openWorkspace()
                }
                .keyboardShortcut("o", modifiers: [.command, .shift])

                Divider()

                // Recent Files submenu
                Menu("Open Recent") {
                    ForEach(appState.recentFiles, id: \.self) { url in
                        Button(url.lastPathComponent) {
                            appState.loadDocument(from: url)
                        }
                    }

                    if !appState.recentFiles.isEmpty {
                        Divider()
                        Button("Clear Menu") {
                            appState.clearRecentFiles()
                        }
                    }

                    if appState.recentFiles.isEmpty {
                        Text("No Recent Items")
                            .foregroundColor(.secondary)
                    }
                }
            }

            CommandGroup(replacing: .saveItem) {
                Button("Save") {
                    appState.saveCurrentDocument()
                }
                .keyboardShortcut("s", modifiers: .command)

                Button("Save As...") {
                    appState.saveDocumentAs()
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])

                Divider()

                Button("Close Tab") {
                    appState.closeCurrentTab()
                }
                .keyboardShortcut("w", modifiers: .command)

                Button("Reopen Closed Tab") {
                    appState.reopenLastClosedTab()
                }
                .keyboardShortcut("t", modifiers: [.command, .shift])
                .disabled(appState.closedTabs.isEmpty)
            }

            CommandGroup(replacing: .printItem) {
                Button("Print...") {
                    appState.printDocument()
                }
                .keyboardShortcut("p", modifiers: .command)
            }

            // Edit menu
            CommandMenu("Edit") {
                Button("Undo") {
                    performUndoAction()
                }
                .keyboardShortcut("z", modifiers: .command)

                Button("Redo") {
                    performRedoAction()
                }
                .keyboardShortcut("z", modifiers: [.command, .shift])

                Divider()

                Button("Cut") {
                    NSApp.sendAction(#selector(NSTextView.cut(_:)), to: nil, from: nil)
                }
                .keyboardShortcut("x", modifiers: .command)

                Button("Copy") {
                    NSApp.sendAction(#selector(NSTextView.copy(_:)), to: nil, from: nil)
                }
                .keyboardShortcut("c", modifiers: .command)

                Button("Paste") {
                    NSApp.sendAction(#selector(NSTextView.paste(_:)), to: nil, from: nil)
                }
                .keyboardShortcut("v", modifiers: .command)

                Divider()

                Button("Select All") {
                    NSApp.sendAction(#selector(NSTextView.selectAll(_:)), to: nil, from: nil)
                }
                .keyboardShortcut("a", modifiers: .command)
            }

            // View menu - add to existing View menu
            CommandGroup(after: .toolbar) {
                Divider()

                Button("Toggle Sidebar") {
                    NotificationCenter.default.post(name: .toggleSidebar, object: nil)
                }
                .keyboardShortcut("0", modifiers: .command)

                Button("Toggle Preview") {
                    NotificationCenter.default.post(name: .togglePreview, object: nil)
                }
                .keyboardShortcut("\\", modifiers: .command)

                Button("Toggle Inspector") {
                    NotificationCenter.default.post(name: .toggleInspector, object: nil)
                }
                .keyboardShortcut("i", modifiers: .command)

                Button("Focus Mode") {
                    NotificationCenter.default.post(name: .toggleFocusMode, object: nil)
                }
                .keyboardShortcut(".", modifiers: [.command, .control])

                Divider()

                Button("Next Tab") {
                    appState.nextTab()
                }
                .keyboardShortcut("]", modifiers: [.command, .shift])
                .disabled(appState.documents.count <= 1)

                Button("Previous Tab") {
                    appState.previousTab()
                }
                .keyboardShortcut("[", modifiers: [.command, .shift])
                .disabled(appState.documents.count <= 1)

                Divider()

                // Tab shortcuts Cmd+1 through Cmd+9
                ForEach(1...9, id: \.self) { index in
                    Button("Tab \(index)") {
                        appState.switchToTab(at: index - 1)
                    }
                    .keyboardShortcut(KeyEquivalent(Character("\(index)")), modifiers: .command)
                    .disabled(index > appState.documents.count)
                }
            }

            // Go menu with command palette
            CommandMenu("Go") {
                Button("Command Palette...") {
                    NotificationCenter.default.post(name: .showCommandPalette, object: nil)
                }
                .keyboardShortcut("k", modifiers: .command)
            }

            // Git menu
            CommandMenu("Git") {
                Button("Stage All") {
                    appState.stageAll()
                }
                .disabled(!appState.isGitRepository || appState.unstagedFiles.isEmpty)

                Button("Unstage All") {
                    appState.unstageAll()
                }
                .disabled(!appState.isGitRepository || appState.stagedFiles.isEmpty)

                Divider()

                Button("Commit...") {
                    NotificationCenter.default.post(name: .showGitCommit, object: nil)
                }
                .keyboardShortcut("k", modifiers: [.command, .shift])
                .disabled(!appState.isGitRepository || appState.stagedFiles.isEmpty)

                Divider()

                Button("Push") {
                    let result = appState.pushChanges()
                    if result.success {
                        if result.alreadyUpToDate {
                            UIStateService.shared.showToast("Already up to date", icon: "checkmark.circle.fill", duration: 2.0)
                        } else {
                            UIStateService.shared.showToast("Push successful", icon: "checkmark.circle.fill", duration: 2.0)
                        }
                    } else {
                        showGitError("Push Failed", result.error)
                    }
                }
                .disabled(!appState.isGitRepository)

                Button("Pull") {
                    let result = appState.pullChanges()
                    if result.success {
                        UIStateService.shared.showToast("Pull successful", icon: "checkmark.circle.fill", duration: 2.0)
                    } else {
                        showGitError("Pull Failed", result.error)
                    }
                }
                .disabled(!appState.isGitRepository)

                Divider()

                Button("Refresh Git Status") {
                    Task {
                        await appState.refreshGitStatus()
                        // Small delay to allow git detection to complete
                        try? await Task.sleep(nanoseconds: 200_000_000) // 200ms
                        await MainActor.run {
                            if appState.isGitRepository {
                                UIStateService.shared.showToast("Git status refreshed", icon: "checkmark.circle.fill", duration: 2.0)
                            } else {
                                UIStateService.shared.showToast("Git repository not found in workspace", icon: "exclamationmark.triangle.fill", duration: 3.0)
                            }
                        }
                    }
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])
                // Always enabled so users can trigger git detection even when not detected
            }

            // Help menu
            CommandGroup(replacing: .help) {
                Button("tibok Help") {
                    if let url = URL(string: "https://www.tibok.app/support") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .keyboardShortcut("?", modifiers: .command)

                Divider()

                Button("View Log File...") {
                    LogService.shared.revealLogFile()
                }

                Button("Copy Log Path") {
                    LogService.shared.copyLogPathToClipboard()
                    UIStateService.shared.showToast(
                        "Log path copied to clipboard",
                        icon: "doc.on.clipboard"
                    )
                }

                Button("Clear Log") {
                    LogService.shared.clearLog()
                    UIStateService.shared.showToast(
                        "Log file cleared",
                        icon: "trash"
                    )
                }

                Divider()

                Button("Report an Issue...") {
                    if let url = URL(string: "https://github.com/sturdy-barnacle/md-editor/issues") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }

            // Format menu with markdown shortcuts
            CommandMenu("Format") {
                Button("Bold") {
                    performFormatting(.bold)
                }
                .keyboardShortcut("b", modifiers: .command)

                Button("Italic") {
                    performFormatting(.italic)
                }
                .keyboardShortcut("i", modifiers: [.command, .shift])

                Button("Strikethrough") {
                    performFormatting(.strikethrough)
                }
                .keyboardShortcut("x", modifiers: [.command, .shift])

                Divider()

                Button("Inline Code") {
                    performFormatting(.code)
                }
                .keyboardShortcut("e", modifiers: .command)

                Button("Link") {
                    performFormatting(.link)
                }
                .keyboardShortcut("l", modifiers: .command)
            }

            // Window menu - add main window item
            CommandGroup(after: .windowList) {
                Divider()

                Button("Main Window") {
                    reopenMainWindow()
                }
                .keyboardShortcut("1", modifiers: [.command, .option])
            }
        }
        .commands {
            // Add Find menu (in separate .commands block to avoid 10-child limit)
            CommandMenu("Find") {
                Button("Find…") {
                    performFind(.showFindPanel)
                }
                .keyboardShortcut("f", modifiers: .command)

                Button("Find Next") {
                    performFind(.next)
                }
                .keyboardShortcut("g", modifiers: .command)

                Button("Find Previous") {
                    performFind(.previous)
                }
                .keyboardShortcut("g", modifiers: [.command, .shift])

                Divider()

                Button("Find and Replace…") {
                    performFind(.replace)
                }
                .keyboardShortcut("f", modifiers: [.command, .option])

                Button("Replace") {
                    performFind(.replaceAndFind)
                }
                .keyboardShortcut("=", modifiers: .command)

                Button("Replace All") {
                    performFind(.replaceAll)
                }
            }
        }

        Settings {
            SettingsView()
        }
    }

    private func applyAppearance() {
        let mode = AppearanceMode(rawValue: appearanceMode) ?? .system
        switch mode {
        case .system:
            NSApp.appearance = nil
        case .light:
            NSApp.appearance = NSAppearance(named: .aqua)
        case .dark:
            NSApp.appearance = NSAppearance(named: .darkAqua)
        }
    }

    private func initializePlugins() {
        // Create plugin directories on first launch
        let fileManager = FileManager.default
        let appSupport = fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/tibok")

        let pluginsDir = appSupport.appendingPathComponent("Plugins")

        // Create directories if they don't exist
        try? fileManager.createDirectory(at: appSupport, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: pluginsDir, withIntermediateDirectories: true)

        PluginManager.shared.initialize(
            slashCommandService: SlashCommandService.shared,
            commandRegistry: CommandService.shared,
            appState: appState
        )
    }

    private func performFormatting(_ type: FormattingType) {
        NotificationCenter.default.post(
            name: .performFormatting,
            object: nil,
            userInfo: ["type": type]
        )
    }

    // MARK: - Objective-C Responder Chain Actions

    /// Perform undo action via responder chain
    /// Note: undo: is an Objective-C method from NSResponder that NSTextView inherits.
    /// We use NSApplication.sendAction to invoke it through the responder chain.
    private func performUndoAction() {
        NSApp.sendAction(NSSelectorFromString("undo:"), to: nil, from: nil)
    }

    /// Perform redo action via responder chain
    /// Note: redo: is an Objective-C method from NSResponder that NSTextView inherits.
    /// We use NSApplication.sendAction to invoke it through the responder chain.
    private func performRedoAction() {
        NSApp.sendAction(NSSelectorFromString("redo:"), to: nil, from: nil)
    }
}

// MARK: - Formatting Types

enum FormattingType: String {
    case bold
    case italic
    case strikethrough
    case code
    case link
}

// MARK: - Git Error Helper

func showGitError(_ title: String, _ message: String?) {
    let alert = NSAlert()
    alert.messageText = title
    alert.informativeText = message ?? "Unknown error"
    alert.alertStyle = .warning
    alert.addButton(withTitle: "OK")
    alert.runModal()
}

// MARK: - Find Panel Support

/// Routes find panel actions to the first responder (NSTextView)
func performFind(_ action: NSFindPanelAction) {
    // Create a menu item with the appropriate tag for the find action
    let menuItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    menuItem.tag = Int(action.rawValue)

    // Send the action through the responder chain
    NSApp.sendAction(#selector(NSTextView.performFindPanelAction(_:)), to: nil, from: menuItem)
}

// MARK: - Help Support

/// Opens the main help documentation
func openHelp() {
    openHelpFile("README.md", title: "tibok Help")
}

/// Opens a specific help file from user_docs in an in-app window
func openHelpFile(_ relativePath: String, title: String? = nil) {
    var fileURL: URL?

    // Try to find user_docs in the app bundle
    if let resourceURL = Bundle.main.resourceURL {
        let docsInBundle = resourceURL.appendingPathComponent("user_docs").appendingPathComponent(relativePath)
        if FileManager.default.fileExists(atPath: docsInBundle.path) {
            fileURL = docsInBundle
        }
    }

    // Fallback: Try development paths (when running from Xcode or swift run)
    if fileURL == nil {
        // Try path relative to executable (for development builds)
        let executableURL = Bundle.main.executableURL ?? URL(fileURLWithPath: CommandLine.arguments[0])
        let possiblePaths = [
            // From .build/debug/tibok -> project root
            executableURL.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
                .appendingPathComponent("user_docs").appendingPathComponent(relativePath),
            // From .build/debug/tibok.app/Contents/MacOS/tibok -> project root
            executableURL.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
                .deletingLastPathComponent().deletingLastPathComponent()
                .appendingPathComponent("user_docs").appendingPathComponent(relativePath),
            // Current working directory
            URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                .appendingPathComponent("user_docs").appendingPathComponent(relativePath)
        ]

        for path in possiblePaths {
            if FileManager.default.fileExists(atPath: path.path) {
                fileURL = path
                break
            }
        }
    }

    guard let url = fileURL else {
        // Last resort: Show alert that help isn't available
        let alert = NSAlert()
        alert.messageText = "Help Not Available"
        alert.informativeText = "Could not find the help documentation. Please check that user_docs folder exists."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
        return
    }

    // Read markdown content and open in-app help window
    do {
        let content = try String(contentsOf: url, encoding: .utf8)
        let windowTitle = title ?? url.deletingPathExtension().lastPathComponent
        HelpWindowController.shared.showHelp(content: content, title: windowTitle, baseURL: url)
    } catch {
        let alert = NSAlert()
        alert.messageText = "Could Not Read Help File"
        alert.informativeText = "Error: \(error.localizedDescription)"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}

// MARK: - Help Window Controller

class HelpWindowController {
    static let shared = HelpWindowController()
    private var window: NSWindow?
    private var windowDelegate: HelpWindowDelegate?

    func showHelp(content: String, title: String, baseURL: URL? = nil) {
        // Close existing window if open
        window?.close()
        window = nil

        // Create the help view
        let helpView = HelpContentView(markdownContent: content, title: title, baseURL: baseURL)
        let hostingView = NSHostingView(rootView: helpView)

        // Create window
        let newWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 600),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        newWindow.title = title
        newWindow.contentView = hostingView
        newWindow.center()
        newWindow.setFrameAutosaveName("HelpWindow")
        newWindow.isReleasedWhenClosed = false

        // Keep delegate alive
        let delegate = HelpWindowDelegate()
        newWindow.delegate = delegate
        self.windowDelegate = delegate

        self.window = newWindow

        // Ensure window appears in front
        NSApp.activate(ignoringOtherApps: true)
        newWindow.makeKeyAndOrderFront(nil)
    }
}

class HelpWindowDelegate: NSObject, NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        // Allow window to close normally
    }
}

// MARK: - Help Content View

struct HelpContentView: View {
    let markdownContent: String
    let title: String
    let baseURL: URL?

    private var renderedHTML: String {
        let html = MarkdownRenderer.render(markdownContent)
        return wrapInHTMLTemplate(html)
    }

    var body: some View {
        HelpWebView(html: renderedHTML, baseURL: baseURL)
            .frame(minWidth: 400, minHeight: 300)
    }

    private func wrapInHTMLTemplate(_ content: String) -> String {
        """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <style>
                :root {
                    color-scheme: light dark;
                    -webkit-user-select: text;
                    user-select: text;
                }
                * {
                    -webkit-user-modify: read-only !important;
                }
                body {
                    font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                    font-size: 15px;
                    line-height: 1.6;
                    color: #1a1a1a;
                    max-width: 100%;
                    margin: 0;
                    padding: 24px 32px;
                    background: transparent;
                }
                h1 { font-size: 28px; font-weight: 700; margin: 0 0 16px 0; border-bottom: 1px solid #e5e5e5; padding-bottom: 8px; }
                h2 { font-size: 22px; font-weight: 600; margin: 28px 0 12px 0; }
                h3 { font-size: 18px; font-weight: 600; margin: 20px 0 8px 0; }
                h4 { font-size: 15px; font-weight: 600; margin: 16px 0 6px 0; }
                p { margin: 0 0 14px 0; }
                code {
                    font-family: 'SF Mono', Menlo, monospace;
                    background: #f5f5f5;
                    padding: 2px 6px;
                    border-radius: 4px;
                    font-size: 13px;
                }
                pre {
                    background: #f5f5f5;
                    padding: 14px;
                    border-radius: 6px;
                    overflow-x: auto;
                    margin: 0 0 14px 0;
                }
                pre code {
                    background: none;
                    padding: 0;
                    font-size: 12px;
                    line-height: 1.5;
                }
                blockquote {
                    border-left: 3px solid #e5e5e5;
                    margin: 0 0 14px 0;
                    padding: 0 0 0 14px;
                    color: #6b6b6b;
                }
                a { color: #0366d6; text-decoration: none; }
                a:hover { text-decoration: underline; }
                ul, ol { margin: 0 0 14px 0; padding-left: 24px; }
                li { margin-bottom: 4px; }
                hr { border: none; border-top: 1px solid #e5e5e5; margin: 20px 0; }
                table { border-collapse: collapse; margin: 0 0 14px 0; width: 100%; }
                th, td { border: 1px solid #e5e5e5; padding: 8px 12px; text-align: left; }
                th { background: #f9f9f9; font-weight: 600; }
                kbd {
                    background: #f5f5f5;
                    border: 1px solid #d0d0d0;
                    border-radius: 4px;
                    padding: 2px 6px;
                    font-family: 'SF Mono', Menlo, monospace;
                    font-size: 12px;
                }

                @media (prefers-color-scheme: dark) {
                    body { color: #e5e5e5; }
                    h1 { border-bottom-color: #3d3d3d; }
                    code { background: #2d2d2d; }
                    pre { background: #2d2d2d; }
                    blockquote { border-left-color: #3d3d3d; color: #8e8e93; }
                    a { color: #58a6ff; }
                    hr { border-top-color: #3d3d3d; }
                    th, td { border-color: #3d3d3d; }
                    th { background: #2d2d2d; }
                    kbd { background: #2d2d2d; border-color: #4d4d4d; }
                }
            </style>
        </head>
        <body>
            \(content)
        </body>
        </html>
        """
    }
}

// MARK: - Help WebView

struct HelpWebView: NSViewRepresentable {
    let html: String
    let baseURL: URL?

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.setValue(false, forKey: "drawsBackground")
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        let htmlWithNoEdit = html.replacingOccurrences(
            of: "<body>",
            with: "<body contenteditable=\"false\" style=\"-webkit-user-modify: read-only;\">"
        )
        webView.loadHTMLString(htmlWithNoEdit, baseURL: baseURL)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }

            // Handle local markdown files (e.g., clicking "FAQ.md")
            if url.isFileURL && url.pathExtension.lowercased() == "md" {
                decisionHandler(.cancel)

                DispatchQueue.main.async {
                    do {
                        // Remove potential fragment (#section) for reading file
                        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
                        components?.fragment = nil

                        if let fileURL = components?.url {
                            let content = try String(contentsOf: fileURL, encoding: .utf8)
                            let title = fileURL.deletingPathExtension().lastPathComponent
                            // Recursively show help for the new file
                            HelpWindowController.shared.showHelp(content: content, title: title, baseURL: fileURL)
                        }
                    } catch {
                        // Navigation failed silently - user can try again
                    }
                }
                return
            }

            // Open external links in default browser
            if url.scheme == "http" || url.scheme == "https" {
                decisionHandler(.cancel)
                NSWorkspace.shared.open(url)
                return
            }

            // Allow other navigation (like anchors within the same page)
            decisionHandler(.allow)
        }
    }
}

// MARK: - Main Window Content

/// Wrapper view that captures the openWindow environment action for later use
struct MainWindowContent: View {
    @ObservedObject var appState: AppState
    let windowTitle: String
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        ContentView()
            .environmentObject(appState)
            .onOpenURL { url in
                appState.loadDocument(from: url)
            }
            .navigationTitle(windowTitle)
            .onAppear {
                // Store the openWindow action for use outside SwiftUI
                WindowAccessor.shared.openWindow = { id in
                    openWindow(id: id)
                }
            }
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate {
    /// Called when the user clicks the dock icon while the app is running
    /// This handles the case where all windows are closed but the app is still active
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            // No visible windows - reopen the main window
            reopenMainWindow()
        }
        return true
    }
}

// MARK: - Window Management

/// Reopens the main application window
/// SwiftUI's WindowGroup automatically manages a single main window.
/// When all windows are closed, we can trigger a new window by using openWindow or
/// by activating the app which causes WindowGroup to create a new window instance.
func reopenMainWindow() {
    // First, check if there's an existing window we can just bring forward
    if let existingWindow = NSApp.windows.first(where: { window in
        // Find the main content window (not settings, help, or panels)
        window.isVisible && window.title.contains("tibok")
    }) {
        existingWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        return
    }

    // If no main window exists, we need to trigger WindowGroup to create one
    // Use the openWindow action stored by WindowAccessor
    if let openWindow = WindowAccessor.shared.openWindow {
        openWindow("main")
        NSApp.activate(ignoringOtherApps: true)
        return
    }

    // Fallback: Activate the app which often triggers window creation
    NSApp.activate(ignoringOtherApps: true)
}

// MARK: - Window Accessor

/// Stores SwiftUI Environment actions for use outside of SwiftUI views
class WindowAccessor {
    static let shared = WindowAccessor()
    var openWindow: ((_ id: String) -> Void)?
}
