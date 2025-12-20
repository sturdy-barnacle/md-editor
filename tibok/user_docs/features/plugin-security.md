# Plugin Security

This document explains the security model for tibok plugins, including best practices for developers and guidelines for users.

For the complete security architecture, see [Plugin Security Model](../../planning/plugin-security-model.md).

## Overview

Plugins extend tibok with new functionality. To maintain security and stability:

- **Plugins are user-installed**: Users intentionally add plugins from trusted sources
- **Plugins have limited scope**: Plugins can only access specific tibok APIs
- **Future code signing**: All plugins will require code signing for distribution
- **Transparency**: Plugin capabilities are declared in manifests

## For Plugin Users

### Installing Plugins Safely

When installing a plugin:

1. **Check the source**: Only install plugins from trusted developers or official repositories
2. **Review permissions**: Check what the plugin declares in its manifest
3. **Read the README**: Understand what the plugin does and who maintains it
4. **Start small**: Test plugins one at a time to isolate issues
5. **Keep tibok updated**: Updates include security fixes

### What Plugins Can Do

Plugins can:

- ✅ Insert text into documents
- ✅ Register slash commands and palette commands
- ✅ Access document metadata (filename, content, frontmatter)
- ✅ Access app state (current document, workspace info)
- ✅ Receive app events (notifications)

### What Plugins Cannot Do

Plugins cannot:

- ❌ Access the file system (except through provided APIs)
- ❌ Make network requests (unless declared)
- ❌ Access system files or other applications
- ❌ Modify tibok settings without permission
- ❌ Run arbitrary code outside the sandbox
- ❌ Access user credentials or keychain

### Disabling or Removing Plugins

**Disable a plugin** (keep it installed):
1. Go to Settings → Plugins
2. Toggle off the plugin
3. tibok removes its commands immediately

**Remove a plugin** (delete it completely):
1. Disable the plugin first
2. Open Finder
3. Navigate to `~/Library/Application Support/tibok/Plugins/ThirdParty/`
4. Delete the plugin folder
5. Restart tibok

### Reporting Security Issues

If you find a security issue in a plugin:

1. **Contact the plugin author** directly (check plugin README)
2. **Do not share publicly** until fixed
3. **Report to tibok** if the issue affects the core system

For tibok core security issues:
- Email: security@tibok.app (future)
- Do not create public GitHub issues for security problems

## For Plugin Developers

### Security Best Practices

#### 1. Input Validation

Always validate input from documents and users:

```swift
// ❌ Don't: Trust user input
func process(text: String) {
    let result = eval(text)  // Dangerous!
    return result
}

// ✅ Do: Validate input
func process(text: String) {
    guard text.count < 1000 else { return nil }
    guard text.allSatisfy({ $0.isLetter || $0.isWhitespace }) else { return nil }
    return text
}
```

#### 2. Minimize Permissions

Only declare capabilities you actually use:

```json
{
  "identifier": "com.example.plugin",
  "name": "My Plugin",
  "capabilities": ["slash-commands"]
}
```

Don't declare unused permissions:

```json
{
  "capabilities": ["slash-commands", "export", "webhooks", "file-access"]
}
```

#### 3. Handle Errors Gracefully

Never crash the editor:

```swift
// ❌ Don't: Force unwrap
let content = context.currentDocument!.content

// ✅ Do: Handle optional
if let doc = context.currentDocument {
    let content = doc.content
    // Process content
}
```

#### 4. Avoid Performance Issues

Keep command execution fast (< 100ms):

```swift
// ❌ Don't: Block UI thread
let command = SlashCommand(
    name: "slow",
    description: "Slow command",
    icon: "star",
    action: { context in
        sleep(5)  // Blocks UI!
        context?.insertText("Done")
    }
)

// ✅ Do: Defer heavy work
let command = SlashCommand(
    name: "fast",
    description: "Fast command",
    icon: "star",
    action: { context in
        DispatchQueue.global().async {
            let result = expensiveOperation()
            DispatchQueue.main.async {
                context?.insertText(result)
            }
        }
    }
)
```

#### 5. Use @MainActor for UI Access

All UI modifications must happen on the main thread:

```swift
// ✅ Do: Use @MainActor
@MainActor
func updateUI() {
    context?.insertText("Updated")
}

// ✅ Do: Dispatch to main thread
DispatchQueue.main.async {
    context?.insertText("Updated")
}
```

#### 6. Clean Up Resources

Implement proper deactivation:

```swift
func deactivate() {
    // Cancel timers
    timer?.invalidate()
    timer = nil

    // Close file handles
    fileHandle?.closeFile()

    // Remove observers
    NotificationCenter.default.removeObserver(self)
}
```

#### 7. Avoid Retain Cycles

Use weak references in closures:

```swift
// ❌ Don't: Strong reference keeps plugin in memory
let command = SlashCommand(
    name: "test",
    description: "Test",
    icon: "star",
    action: { [self] in  // ← strong reference
        self.doSomething()
    }
)

// ✅ Do: Weak reference
let command = SlashCommand(
    name: "test",
    description: "Test",
    icon: "star",
    action: { [weak self] in  // ← weak reference
        self?.doSomething()
    }
)
```

#### 8. Document Dependencies

Clearly list what your plugin needs:

```json
{
  "identifier": "com.example.plugin",
  "name": "My Plugin",
  "minimumTibokVersion": "0.6.0",
  "capabilities": ["slash-commands", "command-palette"],
  "description": "Requires tibok 0.6.0 or later for API support"
}
```

#### 9. Version Compatibility

Test with multiple tibok versions:

```bash
# Test with different versions
./build-tibok.sh --version 0.6.0
npm test

./build-tibok.sh --version 0.7.0
npm test
```

#### 10. Code Review

Have someone else review your code before release.

### Sandboxing Model

Plugins run with limited access to protect the system:

| Resource | Access | Notes |
|----------|--------|-------|
| Editor content | ✅ Read/Write | Via insertText() |
| Document metadata | ✅ Read | Filename, path, frontmatter |
| App state | ✅ Read | Branch, git status, workspace |
| Slash commands | ✅ Register | Via API |
| Command palette | ✅ Register | Via API |
| File system | ❌ No | Future: restricted file access |
| Network | ❌ No | Future: restricted network |
| System libraries | ❌ No | Only Foundation + standard libs |

### Declaring Capabilities

Declare what your plugin uses in manifest.json:

```json
{
  "identifier": "com.example.plugin",
  "capabilities": [
    "slash-commands",      // Register slash commands
    "command-palette",     // Register palette commands
    "document-access",     // Read document content
    "git-access"           // Access git information
  ]
}
```

**Standard capabilities**:
- `slash-commands` - Register slash commands
- `command-palette` - Register command palette commands
- `document-access` - Read document metadata
- `export` - Custom export formats (future)
- `webhooks` - Receive webhook notifications (future)

### Code Signing (Future)

In a future release, tibok will require code signing for distributed plugins:

**What this means**:
- You sign your plugin with your private key
- Users can verify your identity
- Protects against tampering
- Required for ThirdParty and Community folders

**What this requires**:
- Developer account
- Code signing certificate
- Key management
- Versioning and distribution

**We'll provide**:
- Code signing tools
- Detailed documentation
- Community certificate authority (potentially)

For now, develop locally in the Dev folder.

### Testing for Security

Before releasing your plugin:

```swift
// ✅ Test: Handle nil document
let command = SlashCommand(
    name: "test",
    description: "Test",
    icon: "star",
    action: { context in
        if context?.currentDocument == nil {
            print("No document - handled gracefully")
        }
    }
)

// ✅ Test: Handle empty input
func parseInput(_ input: String) {
    guard !input.isEmpty else { return }
    // Process
}

// ✅ Test: Memory usage
// Monitor tibok memory usage before/after enabling plugin

// ✅ Test: Crash recovery
// If plugin crashes, tibok should recover gracefully
```

### Security Checklist

Before releasing your plugin:

- [ ] Input validation on all user input
- [ ] No force-unwrapping
- [ ] Error handling for all operations
- [ ] Proper @MainActor usage
- [ ] Resource cleanup in deactivate()
- [ ] Weak references in closures
- [ ] Manifests declare required capabilities
- [ ] Performance tested (< 100ms per command)
- [ ] Memory leaks tested (Instruments)
- [ ] Works with latest tibok version
- [ ] README explains security implications
- [ ] No hardcoded credentials
- [ ] No logging sensitive data

## Reporting Issues

### For Plugin Users

If you find a security issue:

1. **Document the issue**: Write down steps to reproduce
2. **Contact the author**: Email the plugin creator
3. **Report to tibok**: If it affects the core system
4. **Do not share publicly**: Wait for a fix

### For Plugin Developers

If a user reports a security issue:

1. **Acknowledge quickly**: Respond within 24 hours
2. **Verify the issue**: Test and confirm
3. **Create a fix**: Patch the vulnerability
4. **Release promptly**: Push fix in 48 hours if possible
5. **Notify users**: Explain the fix and recommend updating

## Future Security Features

We plan to add:

- ✅ Plugin manifest validation
- ✅ Plugin sandboxing (enhanced)
- ✅ Code signing for distribution
- ✅ Plugin permissions UI (users can see what each plugin accesses)
- ✅ Plugin runtime monitoring (tibok can detect issues)
- ✅ Automated security scanning (community plugins)
- ✅ Plugin update mechanism (automatic security patches)

## Security Resources

- **OWASP**: https://owasp.org (security best practices)
- **Apple Security**: https://developer.apple.com/security/
- **Swift Security**: https://swift.org/security

## Questions?

- **Security issues**: security@tibok.app (future)
- **Best practices**: GitHub Discussions
- **API questions**: Check plugin development guide
