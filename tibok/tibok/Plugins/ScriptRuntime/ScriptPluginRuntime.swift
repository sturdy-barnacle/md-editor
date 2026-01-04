//
//  ScriptPluginRuntime.swift
//  tibok
//
//  JavaScriptCore-based runtime for script plugins.
//  Provides a sandboxed environment with controlled API access.
//
//  MIT License - See LICENSE file in Plugins directory
//

import Foundation
import JavaScriptCore

/// Sandboxed JavaScript runtime for script plugins.
/// Uses JavaScriptCore which has no default access to system resources.
@MainActor
final class ScriptPluginRuntime: ObservableObject {
    /// The JavaScript context for this plugin
    private let context: JSContext

    /// Plugin identifier
    let pluginId: String

    /// Plugin manifest
    let manifest: PluginManifest

    /// Permissions granted to this plugin
    let permissions: PluginPermissionSet

    /// Registered slash commands from this plugin
    @Published private(set) var registeredSlashCommands: [SlashCommand] = []

    /// Registered palette commands from this plugin
    @Published private(set) var registeredCommands: [Command] = []

    /// Stored execute functions for dynamic slash commands (keyed by command name)
    private var slashCommandExecutors: [String: JSValue] = [:]

    /// Stored action functions for command palette commands (keyed by command id)
    private var commandActionExecutors: [String: JSValue] = [:]

    /// Reference to app state (weak to avoid retain cycles)
    private weak var appState: AppState?

    /// Error handler for script exceptions
    var onError: ((String) -> Void)?

    init(pluginId: String, manifest: PluginManifest, appState: AppState?) {
        self.pluginId = pluginId
        self.manifest = manifest
        self.permissions = manifest.permissionSet
        self.appState = appState

        // Create a new JavaScript context
        self.context = JSContext()!

        // Set up exception handler
        context.exceptionHandler = { [weak self] _, exception in
            let message = exception?.toString() ?? "Unknown JavaScript error"
            print("[\(self?.pluginId ?? "unknown")] JS Error: \(message)")
            self?.onError?(message)
        }

        // Set up the sandboxed API
        setupTibokAPI()
    }

    // MARK: - API Setup

    /// Set up the tibok API object exposed to JavaScript
    private func setupTibokAPI() {
        // Create the main tibok namespace object
        let tibok = JSValue(newObjectIn: context)!

        // Add version info
        tibok.setObject("1.0.0", forKeyedSubscript: "version" as NSString)
        tibok.setObject(pluginId, forKeyedSubscript: "pluginId" as NSString)

        // Add sub-APIs based on permissions
        if permissions.has(.slashCommands) {
            tibok.setObject(createSlashCommandsAPI(), forKeyedSubscript: "slashCommands" as NSString)
        }

        if permissions.has(.commandPalette) {
            tibok.setObject(createCommandPaletteAPI(), forKeyedSubscript: "commands" as NSString)
        }

        if permissions.has(.readCurrentDocument) || permissions.has(.insertText) || permissions.has(.readSelection) {
            tibok.setObject(createEditorAPI(), forKeyedSubscript: "editor" as NSString)
        }

        if permissions.has(.readDocumentMetadata) {
            tibok.setObject(createDocumentAPI(), forKeyedSubscript: "document" as NSString)
        }

        // Add utility APIs (always available)
        tibok.setObject(createLogAPI(), forKeyedSubscript: "log" as NSString)
        tibok.setObject(createSettingsAPI(), forKeyedSubscript: "settings" as NSString)

        // Expose the tibok object globally
        context.setObject(tibok, forKeyedSubscript: "tibok" as NSString)

        // Also expose console.log for convenience
        setupConsoleAPI()
    }

    // MARK: - Slash Commands API

    private func createSlashCommandsAPI() -> JSValue {
        let api = JSValue(newObjectIn: context)!

        // tibok.slashCommands.register(command)
        let register: @convention(block) (JSValue) -> Bool = { [weak self] commandValue in
            guard let self = self else { return false }
            return self.registerSlashCommand(from: commandValue)
        }
        api.setObject(register, forKeyedSubscript: "register" as NSString)

        // tibok.slashCommands.registerMany(commands)
        let registerMany: @convention(block) (JSValue) -> Int = { [weak self] commandsArray in
            guard let self = self,
                  let commands = commandsArray.toArray() as? [[String: Any]] else { return 0 }

            var count = 0
            for commandDict in commands {
                if let jsValue = JSValue(object: commandDict, in: self.context),
                   self.registerSlashCommand(from: jsValue) {
                    count += 1
                }
            }
            return count
        }
        api.setObject(registerMany, forKeyedSubscript: "registerMany" as NSString)

        return api
    }

    private func registerSlashCommand(from jsValue: JSValue) -> Bool {
        guard let dict = jsValue.toDictionary() as? [String: Any] else { return false }

        guard let name = dict["name"] as? String,
              let description = dict["description"] as? String else {
            print("[\(pluginId)] Slash command missing required fields (name, description)")
            return false
        }

        let id = "\(pluginId):\(name)"
        let icon = dict["icon"] as? String ?? "sparkle"
        let keywords = dict["keywords"] as? [String] ?? []
        let categoryString = dict["category"] as? String ?? "general"
        let category = SlashCommandCategory(rawValue: categoryString) ?? .general

        // Get the insert template or execute function
        var insertText = ""
        if let insert = dict["insert"] as? String {
            insertText = insert
        } else if let executeFunc = jsValue.forProperty("execute"), executeFunc.isObject {
            // Store the execute function for later invocation
            slashCommandExecutors[name] = executeFunc
            insertText = "{{DYNAMIC:\(id)}}"
        }

        let command = SlashCommand(
            id: id,
            name: name,
            description: description,
            icon: icon,
            insert: insertText,
            source: pluginId,
            keywords: keywords,
            category: category
        )

        registeredSlashCommands.append(command)
        print("[DEBUG] [\(pluginId)] Slash command registered: /\(name) -> '\(insertText.prefix(30))...'")
        return true
    }

    // MARK: - Command Palette API

    private func createCommandPaletteAPI() -> JSValue {
        let api = JSValue(newObjectIn: context)!

        // tibok.commands.register(command)
        let register: @convention(block) (JSValue) -> Bool = { [weak self] commandValue in
            guard let self = self else { return false }
            return self.registerCommand(from: commandValue)
        }
        api.setObject(register, forKeyedSubscript: "register" as NSString)

        return api
    }

    private func registerCommand(from jsValue: JSValue) -> Bool {
        guard let dict = jsValue.toDictionary() as? [String: Any] else { return false }

        guard let title = dict["title"] as? String else {
            print("[\(pluginId)] Command missing required field: title")
            return false
        }

        let id = "\(pluginId):\(dict["id"] as? String ?? title.lowercased().replacingOccurrences(of: " ", with: "-"))"
        let subtitle = dict["subtitle"] as? String
        let icon = dict["icon"] as? String
        let categoryString = dict["category"] as? String ?? "general"
        // Capitalize to match Swift enum rawValues (e.g., "edit" -> "Edit")
        let category = CommandCategory(rawValue: categoryString.capitalized) ?? .general

        // Get the action function
        guard let actionFunc = jsValue.forProperty("action"),
              actionFunc.isObject else {
            print("[\(pluginId)] Command missing action function")
            return false
        }

        // Store the action function to prevent JavaScriptCore GC
        commandActionExecutors[id] = actionFunc

        let command = Command(
            id: id,
            title: title,
            subtitle: subtitle,
            icon: icon,
            category: category,
            source: pluginId
        ) { [weak self] in
            // Execute the JavaScript action via stored reference
            self?.executeCommandAction(id: id)
        }

        registeredCommands.append(command)
        print("[DEBUG] [\(pluginId)] Command registered: '\(title)' (id: \(id), category: \(category))")
        return true
    }

    /// Execute a stored command palette action by id
    private func executeCommandAction(id: String) {
        guard let action = commandActionExecutors[id] else {
            print("[\(pluginId)] No action found for command: \(id)")
            return
        }
        action.call(withArguments: [])
    }

    /// Execute a stored slash command by name
    func executeSlashCommand(name: String) {
        guard let executor = slashCommandExecutors[name] else {
            print("[\(pluginId)] No executor found for slash command: \(name)")
            return
        }
        // Call the JavaScript execute function
        executor.call(withArguments: [])
    }

    // MARK: - Editor API

    private func createEditorAPI() -> JSValue {
        let api = JSValue(newObjectIn: context)!

        // tibok.editor.insertText(text)
        if permissions.has(.insertText) {
            let insertText: @convention(block) (String) -> Void = { [weak self] text in
                guard self != nil else { return }
                Task { @MainActor in
                    EditorService.shared.insertText(text)
                }
            }
            api.setObject(insertText, forKeyedSubscript: "insertText" as NSString)
        }

        // tibok.editor.replaceSelection(text)
        if permissions.has(.insertText) {
            let replaceSelection: @convention(block) (String) -> Void = { [weak self] text in
                guard self != nil else { return }
                Task { @MainActor in
                    EditorService.shared.replaceSelection(with: text)
                }
            }
            api.setObject(replaceSelection, forKeyedSubscript: "replaceSelection" as NSString)
        }

        // tibok.editor.getSelectedText()
        if permissions.has(.readSelection) {
            let getSelectedText: @convention(block) () -> String = { [weak self] in
                guard self != nil else { return "" }
                return EditorService.shared.getSelectedText()
            }
            api.setObject(getSelectedText, forKeyedSubscript: "getSelectedText" as NSString)
        }

        // tibok.editor.getContent()
        if permissions.has(.readCurrentDocument) {
            let getContent: @convention(block) () -> String = { [weak self] in
                guard let self = self else { return "" }
                return self.appState?.currentDocument.content ?? ""
            }
            api.setObject(getContent, forKeyedSubscript: "getContent" as NSString)
        }

        // tibok.editor.getCursorPosition()
        if permissions.has(.readSelection) {
            let getCursorPosition: @convention(block) () -> [String: Int] = { [weak self] in
                guard self != nil else { return ["position": 0] }
                return ["position": EditorService.shared.getCursorPosition()]
            }
            api.setObject(getCursorPosition, forKeyedSubscript: "getCursorPosition" as NSString)
        }

        // tibok.editor.getSelectionRange()
        if permissions.has(.readSelection) {
            let getSelectionRange: @convention(block) () -> [String: Int] = { [weak self] in
                guard self != nil else { return ["location": 0, "length": 0] }
                let range = EditorService.shared.getSelectionRange()
                return ["location": range.location, "length": range.length]
            }
            api.setObject(getSelectionRange, forKeyedSubscript: "getSelectionRange" as NSString)
        }

        // tibok.editor.setSelectionRange(location, length)
        if permissions.has(.readSelection) {
            let setSelectionRange: @convention(block) (Int, Int) -> Void = { [weak self] location, length in
                guard self != nil else { return }
                Task { @MainActor in
                    EditorService.shared.setSelectionRange(NSRange(location: location, length: length))
                }
            }
            api.setObject(setSelectionRange, forKeyedSubscript: "setSelectionRange" as NSString)
        }

        return api
    }

    // MARK: - Document API

    private func createDocumentAPI() -> JSValue {
        let api = JSValue(newObjectIn: context)!

        // tibok.document.getFilename()
        let getFilename: @convention(block) () -> String? = { [weak self] in
            guard let doc = self?.appState?.currentDocument else { return nil }
            return doc.fileURL?.lastPathComponent ?? doc.title
        }
        api.setObject(getFilename, forKeyedSubscript: "getFilename" as NSString)

        // tibok.document.getPath()
        let getPath: @convention(block) () -> String? = { [weak self] in
            return self?.appState?.currentDocument.fileURL?.path
        }
        api.setObject(getPath, forKeyedSubscript: "getPath" as NSString)

        // tibok.document.getFrontmatter()
        // TODO: Parse frontmatter from document content when Frontmatter API is available
        let getFrontmatter: @convention(block) () -> [String: Any]? = { [weak self] in
            guard let self = self else { return nil }
            // Placeholder: Return nil for now
            // Future: Parse YAML frontmatter from document content
            print("[\(self.pluginId)] getFrontmatter called")
            return nil
        }
        api.setObject(getFrontmatter, forKeyedSubscript: "getFrontmatter" as NSString)

        // tibok.document.getWordCount()
        let getWordCount: @convention(block) () -> Int = { [weak self] in
            let content = self?.appState?.currentDocument.content ?? ""
            // Simple word count - split on whitespace
            return content.split { $0.isWhitespace }.count
        }
        api.setObject(getWordCount, forKeyedSubscript: "getWordCount" as NSString)

        // tibok.document.getTitle()
        let getTitle: @convention(block) () -> String = { [weak self] in
            return self?.appState?.currentDocument.title ?? "Untitled"
        }
        api.setObject(getTitle, forKeyedSubscript: "getTitle" as NSString)

        // tibok.document.isModified()
        let isModified: @convention(block) () -> Bool = { [weak self] in
            return self?.appState?.currentDocument.isModified ?? false
        }
        api.setObject(isModified, forKeyedSubscript: "isModified" as NSString)

        return api
    }

    // MARK: - Logging API

    private func createLogAPI() -> JSValue {
        let api = JSValue(newObjectIn: context)!

        let log: @convention(block) (String) -> Void = { [weak self] message in
            print("[\(self?.pluginId ?? "unknown")] \(message)")
        }
        api.setObject(log, forKeyedSubscript: "info" as NSString)

        let warn: @convention(block) (String) -> Void = { [weak self] message in
            print("[\(self?.pluginId ?? "unknown")] WARNING: \(message)")
        }
        api.setObject(warn, forKeyedSubscript: "warn" as NSString)

        let error: @convention(block) (String) -> Void = { [weak self] message in
            print("[\(self?.pluginId ?? "unknown")] ERROR: \(message)")
            self?.onError?(message)
        }
        api.setObject(error, forKeyedSubscript: "error" as NSString)

        return api
    }

    private func createSettingsAPI() -> JSValue {
        let api = JSValue(newObjectIn: context)!

        // tibok.settings.get(key) - Read a setting value
        let get: @convention(block) (String) -> Any? = { key in
            // Map known setting keys to UserDefaults
            switch key {
            case "author.signature":
                return UserDefaults.standard.string(forKey: SettingsKeys.authorSignature)
                    ?? "-- Written with Tibok --"
            default:
                return nil
            }
        }
        api.setObject(get, forKeyedSubscript: "get" as NSString)

        return api
    }

    private func setupConsoleAPI() {
        let console = JSValue(newObjectIn: context)!

        let log: @convention(block) (JSValue) -> Void = { [weak self] value in
            print("[\(self?.pluginId ?? "unknown")] console.log:", value.toString() ?? "undefined")
        }
        console.setObject(log, forKeyedSubscript: "log" as NSString)
        console.setObject(log, forKeyedSubscript: "info" as NSString)

        let warn: @convention(block) (JSValue) -> Void = { [weak self] value in
            print("[\(self?.pluginId ?? "unknown")] console.warn:", value.toString() ?? "undefined")
        }
        console.setObject(warn, forKeyedSubscript: "warn" as NSString)

        let error: @convention(block) (JSValue) -> Void = { [weak self] value in
            print("[\(self?.pluginId ?? "unknown")] console.error:", value.toString() ?? "undefined")
        }
        console.setObject(error, forKeyedSubscript: "error" as NSString)

        context.setObject(console, forKeyedSubscript: "console" as NSString)
    }

    // MARK: - Script Execution

    /// Load and execute a JavaScript file
    func loadScript(from url: URL) throws {
        let script = try String(contentsOf: url, encoding: .utf8)
        try executeScript(script, filename: url.lastPathComponent)
    }

    /// Execute JavaScript code
    func executeScript(_ script: String, filename: String = "<script>") throws {
        // Wrap in a try-catch for better error handling
        let wrappedScript = """
        (function() {
            try {
                \(script)
            } catch (e) {
                tibok.log.error("Uncaught exception: " + e.message + "\\n" + (e.stack || ""));
                throw e;
            }
        })();
        """

        let result = context.evaluateScript(wrappedScript)

        // Check for exceptions
        if let exception = context.exception {
            let message = exception.toString() ?? "Unknown error"
            throw ScriptPluginError.executionFailed(filename: filename, message: message)
        }

        // If there's a result, we could handle it, but scripts typically don't return values
        _ = result
    }

    /// Call a JavaScript function by name
    func callFunction(_ name: String, withArguments args: [Any] = []) -> JSValue? {
        guard let function = context.objectForKeyedSubscript(name),
              function.isObject else {
            return nil
        }

        return function.call(withArguments: args)
    }

    // MARK: - Cleanup

    /// Deactivate the runtime and clean up
    func deactivate() {
        // Clear registered commands
        registeredSlashCommands.removeAll()
        registeredCommands.removeAll()

        // Clear stored JavaScript function references
        slashCommandExecutors.removeAll()
        commandActionExecutors.removeAll()

        // The JSContext will be deallocated when this object is released
    }
}

// MARK: - Script Plugin Errors

enum ScriptPluginError: LocalizedError {
    case executionFailed(filename: String, message: String)
    case scriptNotFound(path: String)
    case invalidManifest(String)
    case permissionDenied(PluginPermission)

    var errorDescription: String? {
        switch self {
        case .executionFailed(let filename, let message):
            return "Script '\(filename)' failed: \(message)"
        case .scriptNotFound(let path):
            return "Script not found: \(path)"
        case .invalidManifest(let reason):
            return "Invalid manifest: \(reason)"
        case .permissionDenied(let permission):
            return "Permission denied: \(permission.displayName)"
        }
    }
}
