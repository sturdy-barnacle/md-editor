# Dynamic Plugin Loading Implementation Roadmap

> Technical plan for implementing runtime loading of third-party plugins

**Status:** Planning  
**Target Version:** v1.1  
**Last Updated:** 2025-01-XX

## Overview

Currently, tibok can discover third-party plugins via `manifest.json` files, but cannot load or execute them. This document outlines the implementation plan for dynamic plugin loading.

## Current State

### What Works ✅
- Plugin discovery from `~/Library/Application Support/tibok/Plugins/ThirdParty/`
- Manifest validation and parsing
- Plugin installation via `PluginInstaller`
- Built-in plugin loading (compile-time registration)
- Plugin enable/disable state management

### What's Missing ❌
- Dynamic framework/library loading at runtime
- Type resolution from loaded frameworks
- Plugin class instantiation from manifests
- Error handling for loading failures
- Plugin compilation/build process documentation

## Architecture

### Plugin Format

Third-party plugins must be distributed as **Swift frameworks** (`.framework` bundles):

```
MyPlugin/
├── manifest.json              # Plugin metadata
├── MyPlugin.framework/        # Compiled Swift framework
│   ├── MyPlugin               # Binary executable
│   ├── Headers/               # Public headers (if any)
│   └── Resources/             # Resources (if any)
└── README.md                  # Documentation
```

### Entry Point Resolution

The manifest's `entryPoint` specifies how to load the plugin:

```json
{
  "entryPoint": {
    "framework": "MyPlugin",
    "className": "MyPluginClass"
  }
}
```

**Resolution Process:**
1. Load framework: `MyPlugin.framework`
2. Find class: `MyPluginClass` (conforming to `TibokPlugin`)
3. Instantiate: `MyPluginClass.init()`
4. Register: `plugin.register(with: context)`

## Implementation Plan

### Phase 1: Dynamic Framework Loading

**Goal:** Load Swift frameworks at runtime and resolve plugin classes.

#### 1.1 Create `DynamicPluginLoader` Service

**File:** `tibok/tibok/Plugins/DynamicPluginLoader.swift`

**Responsibilities:**
- Load Swift frameworks using `Bundle.load()` or `dlopen()`
- Resolve plugin classes from framework
- Instantiate plugin instances
- Handle loading errors gracefully

**Key Methods:**
```swift
@MainActor
final class DynamicPluginLoader {
    /// Load a plugin from a framework
    func loadPlugin(
        from frameworkURL: URL,
        className: String,
        identifier: String
    ) throws -> any TibokPlugin
    
    /// Unload a framework
    func unloadFramework(at url: URL) throws
    
    /// Check if framework is loaded
    func isFrameworkLoaded(at url: URL) -> Bool
}
```

**Implementation Notes:**
- Use `Bundle(url:)` to load frameworks
- Use `NSClassFromString()` or `objc_getClass()` to resolve classes
- Cast to `TibokPlugin.Type` protocol
- Handle `@MainActor` requirements
- Validate plugin conformance before instantiation

#### 1.2 Update `PluginManager`

**Changes to `PluginManager.swift`:**

1. **Add dynamic loading support:**
   ```swift
   private let dynamicLoader = DynamicPluginLoader()
   private var loadedFrameworks: [URL: Bundle] = [:]
   ```

2. **Update `enablePlugin()` to handle discovered plugins:**
   ```swift
   func enablePlugin(_ identifier: String) {
       guard let context = context else { return }
       stateManager.setEnabled(identifier, true)
       
       // Try built-in plugins first
       if let pluginType = availablePluginTypes.first(where: { $0.identifier == identifier }) {
           loadPlugin(pluginType, context: context)
           return
       }
       
       // Try discovered plugins (dynamic loading)
       if let discovered = discoveredManifests.first(where: { $0.manifest.identifier == identifier }) {
           loadDiscoveredPlugin(discovered, context: context)
       }
   }
   ```

3. **Add `loadDiscoveredPlugin()` method:**
   ```swift
   private func loadDiscoveredPlugin(
       _ discovered: (url: URL, manifest: PluginManifest, source: PluginSource),
       context: PluginContext
   ) {
       let identifier = discovered.manifest.identifier
       
       guard !isLoaded(identifier) else { return }
       
       do {
           // Validate entry point
           guard let entryPoint = discovered.manifest.entryPoint,
                 let frameworkName = entryPoint.framework,
                 let className = entryPoint.className else {
               throw PluginLoadingError.missingEntryPoint
           }
           
           // Find framework
           let frameworkURL = discovered.url.appendingPathComponent("\(frameworkName).framework")
           guard FileManager.default.fileExists(atPath: frameworkURL.path) else {
               throw PluginLoadingError.frameworkNotFound(frameworkName)
           }
           
           // Load plugin dynamically
           let plugin = try dynamicLoader.loadPlugin(
               from: frameworkURL,
               className: className,
               identifier: identifier
           )
           
           // Register plugin
           plugin.register(with: context)
           loadedPlugins.append(plugin)
           
           // Track framework bundle
           if let bundle = Bundle(url: frameworkURL) {
               loadedFrameworks[frameworkURL] = bundle
           }
           
           pluginErrors.removeValue(forKey: identifier)
           
       } catch {
           pluginErrors[identifier] = error
           print("Failed to load plugin \(identifier): \(error)")
       }
   }
   ```

4. **Update `unloadPlugin()` to handle framework unloading:**
   ```swift
   func unloadPlugin(_ identifier: String) {
       // ... existing unload logic ...
       
       // Unload framework if it was dynamically loaded
       if let discovered = discoveredManifests.first(where: { $0.manifest.identifier == identifier }),
          let entryPoint = discovered.manifest.entryPoint,
          let frameworkName = entryPoint.framework {
           let frameworkURL = discovered.url.appendingPathComponent("\(frameworkName).framework")
           if let bundle = loadedFrameworks[frameworkURL] {
               // Note: macOS doesn't support unloading bundles easily
               // We'll mark as unloaded but keep bundle in memory
               loadedFrameworks.removeValue(forKey: frameworkURL)
           }
       }
   }
   ```

#### 1.3 Error Types

**File:** `tibok/tibok/Plugins/PluginLoadingError.swift`

```swift
enum PluginLoadingError: LocalizedError {
    case frameworkNotFound(String)
    case classNotFound(String)
    case invalidPluginType(String)
    case missingEntryPoint
    case frameworkLoadFailed(URL, Error)
    case pluginInitializationFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .frameworkNotFound(let name):
            return "Framework '\(name).framework' not found"
        case .classNotFound(let name):
            return "Plugin class '\(name)' not found in framework"
        case .invalidPluginType(let name):
            return "Class '\(name)' does not conform to TibokPlugin protocol"
        case .missingEntryPoint:
            return "Plugin manifest missing entryPoint configuration"
        case .frameworkLoadFailed(let url, let error):
            return "Failed to load framework at \(url.path): \(error.localizedDescription)"
        case .pluginInitializationFailed(let error):
            return "Failed to initialize plugin: \(error.localizedDescription)"
        }
    }
}
```

### Phase 2: Plugin Compilation & Distribution

**Goal:** Document and support plugin compilation as Swift frameworks.

#### 2.1 Plugin Build System

Plugins need to be compiled as Swift frameworks. Options:

**Option A: Xcode Project Template**
- Provide Xcode project template for plugin development
- Configure framework target with proper settings
- Include tibok plugin protocol headers

**Option B: Swift Package Manager**
- Plugins can be Swift packages
- Build as frameworks using `swift build`
- Package manifest includes framework product

**Option C: Manual Build Script**
- Provide build script for compiling plugins
- Uses `swiftc` directly to build framework

**Recommended:** Start with Option B (SPM), add Option A later.

#### 2.2 Plugin SDK Distribution

**Create:** `tibok-plugin-sdk` repository (public, MIT licensed)

**Contents:**
- `TibokPlugin.swift` protocol definition
- `PluginContext.swift` API definitions
- `SlashCommand.swift` and `Command.swift` types
- Build scripts and templates
- Example plugins
- Documentation

**Distribution:**
- Swift Package (via GitHub)
- Xcode project template (optional)
- Documentation site

#### 2.3 Plugin Manifest Updates

**Update `PluginManifest.EntryPoint`:**
```swift
struct EntryPoint: Codable {
    /// Framework name (without .framework extension)
    /// Example: "MyPlugin" → loads "MyPlugin.framework"
    let framework: String?
    
    /// Plugin class name (must conform to TibokPlugin)
    /// Example: "MyPluginClass"
    let className: String?
    
    /// For future: script-based plugins
    let script: String?
    
    /// For future: executable-based plugins
    let executable: String?
}
```

**Validation:**
- `framework` and `className` required for framework-based plugins
- `script` required for script-based plugins (future)
- Only one entry point type allowed

### Phase 3: Security & Validation

**Goal:** Ensure dynamically loaded plugins are safe.

#### 3.1 Framework Validation

**Before Loading:**
- ✅ Verify framework exists and is readable
- ✅ Check framework is properly signed (future: require code signing)
- ✅ Validate framework architecture matches app (arm64/x86_64)
- ✅ Check framework size limits (prevent DoS)
- ✅ Verify framework is in allowed location (ThirdParty folder)

**During Loading:**
- ✅ Catch and handle all loading errors
- ✅ Validate plugin class conforms to `TibokPlugin`
- ✅ Verify plugin identifier matches manifest
- ✅ Check plugin version compatibility

#### 3.2 Runtime Safety

**Isolation:**
- Plugins run in same process (v1.1)
- Future: Isolated processes (v2.0)
- Error boundaries prevent plugin crashes from affecting app

**Monitoring:**
- Log all plugin load/unload events
- Track plugin errors in `pluginErrors` dictionary
- Monitor memory usage (system-level)

### Phase 4: Testing & Documentation

**Goal:** Ensure dynamic loading works reliably.

#### 4.1 Test Plugin

**Create:** `tibok/tibokTests/TestPlugins/TestPlugin/`

**Structure:**
```
TestPlugin/
├── manifest.json
├── TestPlugin.framework/
└── Sources/
    └── TestPlugin.swift
```

**Test Plugin Implementation:**
```swift
@MainActor
final class TestPlugin: TibokPlugin {
    static let identifier = "com.tibok.test-plugin"
    static let name = "Test Plugin"
    static let version = "1.0.0"
    static let description = "Test plugin for dynamic loading"
    static let icon = "puzzlepiece.extension"
    
    init() {}
    
    func register(with context: PluginContext) {
        // Register test commands
    }
    
    func deactivate() {
        // Cleanup
    }
}
```

#### 4.2 Unit Tests

**File:** `tibok/tibokTests/DynamicPluginLoaderTests.swift`

**Test Cases:**
- ✅ Load valid framework plugin
- ✅ Handle missing framework
- ✅ Handle missing class
- ✅ Handle invalid plugin type
- ✅ Handle framework load errors
- ✅ Unload plugin correctly
- ✅ Multiple plugins loading
- ✅ Plugin identifier validation

#### 4.3 Integration Tests

**Test Scenarios:**
- Install plugin via `PluginInstaller`
- Enable plugin in settings
- Verify commands are registered
- Disable plugin
- Verify commands are removed
- Uninstall plugin
- Verify plugin is removed

#### 4.4 Documentation Updates

**Update:**
- `user_docs/features/plugin-development.md` - Add framework compilation guide
- `planning/plugin-api-specification.md` - Document dynamic loading
- `planning/plugin-security-model.md` - Update security model
- Create: `user_docs/features/plugin-compilation.md` - Build guide

### Phase 5: UI/UX Improvements

**Goal:** Better user experience for dynamic plugins.

#### 5.1 Plugin Status Indicators

**In `PluginSettingsView`:**
- Show loading state while plugin loads
- Display error messages for failed plugins
- Show plugin version and compatibility
- Indicate if plugin is dynamically loaded

#### 5.2 Error Messages

**User-Friendly Errors:**
- "Plugin failed to load: Framework not found"
- "Plugin incompatible: Requires tibok 1.1.0 or later"
- "Plugin error: Class 'MyPlugin' not found"

#### 5.3 Plugin Information

**Show in Settings:**
- Plugin source (Built-in vs Community)
- Plugin version
- Framework path (for debugging)
- Load status (Loaded, Failed, Not Loaded)

## Technical Challenges

### 1. Swift Framework Loading

**Challenge:** Loading Swift frameworks dynamically is more complex than Objective-C.

**Solution:**
- Use `Bundle(url:)` to load framework
- Use `NSClassFromString()` with full module path: `"ModuleName.ClassName"`
- May need to use `objc_getClass()` for pure Swift classes
- Consider using `@objc` annotations if needed

### 2. Type Erasure

**Challenge:** `TibokPlugin` is a protocol, not a concrete type.

**Solution:**
- Use type erasure: `AnyTibokPlugin` wrapper (if needed)
- Cast loaded class to `TibokPlugin.Type`
- Use protocol conformance checking

### 3. Module Names

**Challenge:** Swift modules have specific naming requirements.

**Solution:**
- Framework name should match module name
- Document naming conventions in plugin SDK
- Validate module name in manifest

### 4. Architecture Matching

**Challenge:** Framework must match app architecture (arm64 for Apple Silicon).

**Solution:**
- Validate framework architecture before loading
- Support universal binaries (fat frameworks)
- Document architecture requirements

### 5. Unloading Frameworks

**Challenge:** macOS doesn't easily support unloading loaded frameworks.

**Solution:**
- Mark as unloaded but keep in memory (v1.1)
- Future: Use separate processes for plugins (v2.0)
- Document that framework remains loaded until app restart

## Implementation Checklist

### Core Implementation
- [ ] Create `DynamicPluginLoader` service
- [ ] Implement framework loading logic
- [ ] Implement class resolution
- [ ] Add error handling and types
- [ ] Update `PluginManager.enablePlugin()`
- [ ] Update `PluginManager.unloadPlugin()`
- [ ] Add framework tracking

### Validation & Security
- [ ] Framework existence validation
- [ ] Architecture validation
- [ ] Size limit checks
- [ ] Path validation (only ThirdParty folder)
- [ ] Protocol conformance checking
- [ ] Identifier validation

### Testing
- [ ] Create test plugin framework
- [ ] Unit tests for `DynamicPluginLoader`
- [ ] Integration tests for plugin lifecycle
- [ ] Error handling tests
- [ ] Multiple plugin tests

### Documentation
- [ ] Plugin compilation guide
- [ ] Framework structure documentation
- [ ] Update API specification
- [ ] Update security model
- [ ] Plugin SDK setup guide

### UI/UX
- [ ] Loading state indicators
- [ ] Error message display
- [ ] Plugin information display
- [ ] Status indicators

## Future Enhancements

### v1.2
- Plugin update mechanism
- Plugin dependencies
- Plugin configuration UI

### v2.0
- Isolated plugin processes
- Code signing requirement
- Plugin marketplace
- Automated security scanning

## References

- [Apple: Loading Code at Runtime](https://developer.apple.com/documentation/swift/loading-code-at-runtime)
- [Swift Forums: Dynamic Framework Loading](https://forums.swift.org/t/dynamic-framework-loading/12345)
- [Apple: Bundle Programming Guide](https://developer.apple.com/library/archive/documentation/CoreFoundation/Conceptual/CFBundles/)

---

**Next Steps:**
1. Implement `DynamicPluginLoader` service
2. Update `PluginManager` for dynamic loading
3. Create test plugin framework
4. Write unit tests
5. Update documentation

