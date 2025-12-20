# tibok Plugin Security Model

> Comprehensive security architecture for the tibok plugin system

**Status:** Defined (v1.0)  
**Last Updated:** 2025-01-XX  
**Version:** 1.0.0

## Security Philosophy

tibok's plugin security model is based on **principle of least privilege**:

1. **Plugins are user-installed**: Users explicitly choose to install plugins
2. **Sandboxed execution**: Plugins run with limited system access
3. **Capability-based permissions**: Plugins declare what they need
4. **Transparent operation**: Users can see what plugins do
5. **Isolated failures**: Plugin crashes don't affect the core app

## Security Architecture

### 1. Plugin Isolation

**Current Implementation (v1.0):**
- Plugins run in the same process as tibok
- Plugins execute on `@MainActor` (main thread)
- No separate sandbox process (future: isolated plugin processes)

**Isolation Mechanisms:**
- **Weak references**: AppState provided as weak reference to prevent retain cycles
- **Error boundaries**: Plugin errors are caught and logged, don't crash app
- **Resource limits**: Plugins cannot allocate unlimited memory (system limits apply)

### 2. Capability Model

Plugins declare capabilities in `manifest.json`:

```json
{
  "identifier": "com.example.plugin",
  "capabilities": [
    "slash-commands",
    "command-palette",
    "document-access"
  ]
}
```

**Standard Capabilities (v1.0):**
- `slash-commands` - Register slash commands
- `command-palette` - Register command palette commands
- `document-access` - Read document content/metadata (read-only)

**Future Capabilities (planned):**
- `file-read` - Read files from workspace (restricted paths)
- `file-write` - Write files to workspace (restricted paths)
- `network` - Make HTTP requests (with user permission)
- `settings` - Store plugin-specific settings
- `export` - Register custom export formats

### 3. Access Control Matrix

| Resource | Access Level | Notes |
|----------|--------------|-------|
| **Document Content** | ✅ Read | Via `context.appState?.activeDocument` |
| **Document Metadata** | ✅ Read | Filename, path, frontmatter |
| **Workspace Info** | ✅ Read | Workspace URL, file tree |
| **Git State** | ✅ Read | Branch, status, staged files |
| **Slash Commands** | ✅ Register | Via `slashCommandService` |
| **Command Palette** | ✅ Register | Via `commandRegistry` |
| **File System** | ❌ No | No direct file access |
| **Network** | ❌ No | No network requests |
| **System Files** | ❌ No | No system file access |
| **Keychain** | ❌ No | No credential access |
| **Other Apps** | ❌ No | No inter-app communication |
| **Settings** | ❌ No | Cannot modify tibok settings |

### 4. Input Validation

**Plugin Responsibilities:**
- Validate all user input
- Sanitize text before insertion
- Check bounds and limits
- Handle nil/optional values gracefully

**tibok Responsibilities:**
- Validate plugin manifests
- Check capability declarations
- Verify plugin structure
- Monitor plugin execution

### 5. Error Handling

**Plugin Error Isolation:**
```swift
// Plugin errors are caught and logged
do {
    try plugin.register(with: context)
} catch {
    pluginErrors[plugin.identifier] = error
    // Plugin fails to load, but app continues
}
```

**Command Error Handling:**
```swift
// Commands should handle errors gracefully
let command = Command(
    id: "my-command",
    title: "My Command",
    action: {
        do {
            try performAction()
        } catch {
            // Log error, show user-friendly message
            print("Command failed: \(error)")
        }
    }
)
```

## Security Controls

### 1. Manifest Validation

**Required Checks:**
- ✅ Valid JSON structure
- ✅ Required fields present (identifier, name, version)
- ✅ Identifier format (reverse-DNS)
- ✅ Version format (semantic versioning)
- ✅ Capabilities are valid

**Rejected If:**
- ❌ Invalid JSON
- ❌ Missing required fields
- ❌ Malformed identifier
- ❌ Unknown capabilities

### 2. Plugin Structure Validation

**Required Structure:**
```
MyPlugin/
├── manifest.json          # Required
├── MyPlugin.swift         # Required (for future dynamic loading)
└── README.md              # Recommended
```

**Validation:**
- ✅ Manifest exists and is valid
- ✅ Entry point exists (for future dynamic loading)
- ✅ No suspicious file patterns
- ✅ File size limits (prevent DoS)

### 3. Runtime Monitoring

**Current (v1.0):**
- Plugin load errors are logged
- Command execution errors are caught
- Memory usage monitored by system

**Future:**
- Performance monitoring (slow commands)
- Memory leak detection
- Crash reporting
- Security event logging

### 4. Code Signing (Future)

**Planned for v2.0:**
- All distributed plugins must be code-signed
- Signature verification on install
- Revocation support
- Developer identity verification

## Threat Model

### 1. Malicious Plugins

**Threat:** Plugin attempts to:
- Access sensitive files
- Steal credentials
- Modify system settings
- Send data to external servers

**Mitigation:**
- ✅ No file system access (v1.0)
- ✅ No network access (v1.0)
- ✅ No keychain access (v1.0)
- ✅ Read-only AppState access
- ✅ Capability declarations
- ✅ User must explicitly install

### 2. Plugin Vulnerabilities

**Threat:** Plugin has security bugs:
- Buffer overflows
- Injection attacks
- Memory leaks
- Race conditions

**Mitigation:**
- ✅ Swift's memory safety
- ✅ Input validation requirements
- ✅ Error handling requirements
- ✅ Code review recommendations
- ✅ Security best practices documentation

### 3. Plugin Conflicts

**Threat:** Multiple plugins interfere:
- Command ID conflicts
- Resource contention
- State corruption

**Mitigation:**
- ✅ Reverse-DNS command IDs
- ✅ Source tracking for commands
- ✅ Isolated plugin state
- ✅ Clean unregistration

### 4. Performance Attacks

**Threat:** Plugin degrades app performance:
- Infinite loops
- Memory exhaustion
- CPU hogging

**Mitigation:**
- ✅ System resource limits
- ✅ Performance monitoring (future)
- ✅ Timeout mechanisms (future)
- ✅ User can disable plugin

## Security Best Practices

### For Plugin Developers

1. **Minimize Capabilities**
   - Only declare capabilities you use
   - Don't request unnecessary permissions

2. **Validate Input**
   - Always validate user input
   - Check bounds and limits
   - Sanitize before use

3. **Handle Errors**
   - Never force-unwrap
   - Always check optionals
   - Provide user-friendly error messages

4. **Resource Management**
   - Clean up in `deactivate()`
   - Use weak references
   - Cancel timers/observers

5. **No Sensitive Data**
   - Don't log credentials
   - Don't store secrets
   - Don't transmit sensitive data

### For Users

1. **Trust Sources**
   - Only install from trusted developers
   - Check plugin reviews/ratings
   - Verify plugin identity

2. **Review Capabilities**
   - Check what plugin declares
   - Understand what it can do
   - Question excessive permissions

3. **Monitor Behavior**
   - Watch for unexpected behavior
   - Check plugin activity
   - Report suspicious plugins

4. **Keep Updated**
   - Update tibok regularly
   - Update plugins when available
   - Remove unused plugins

## Security Incident Response

### Reporting Security Issues

**For Plugin Issues:**
1. Contact plugin author directly
2. Do not disclose publicly until fixed
3. Report to tibok if affects core system

**For tibok Core Issues:**
- Email: security@tibok.app (future)
- Do not create public GitHub issues
- Include: steps to reproduce, affected versions

### Response Process

1. **Acknowledge** (within 24 hours)
2. **Investigate** (verify and assess)
3. **Fix** (develop patch)
4. **Release** (publish fix promptly)
5. **Notify** (inform users of update)

## Security Roadmap

### v1.0 (Current)
- ✅ Capability declarations
- ✅ Manifest validation
- ✅ Read-only AppState access
- ✅ Error isolation
- ✅ Command source tracking

### v1.1 (Planned)
- 🔄 Enhanced error reporting
- 🔄 Performance monitoring
- 🔄 Plugin health checks

### v2.0 (Planned)
- 🔄 Code signing requirement
- 🔄 Isolated plugin processes
- 🔄 File system access (restricted)
- 🔄 Network access (with permission)
- 🔄 Settings API

### v3.0 (Future)
- 🔄 Plugin marketplace
- 🔄 Automated security scanning
- 🔄 Reputation system
- 🔄 Update mechanism

## Compliance

### macOS App Sandbox
- tibok runs with App Sandbox enabled
- Plugins inherit sandbox restrictions
- Additional restrictions via capability model

### Privacy
- Plugins cannot access user data without permission
- No telemetry without user consent
- Transparent data usage

### Security Standards
- Follows OWASP guidelines
- Swift memory safety
- Apple security best practices

## References

- [Plugin API Specification](./plugin-api-specification.md)
- [Plugin Development Guide](../user_docs/features/plugin-development.md)
- [Plugin Security Guide](../user_docs/features/plugin-security.md)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Apple App Sandbox](https://developer.apple.com/documentation/security/app_sandbox)

---

**This security model is defined as of tibok v1.0. Updates will be documented as the model evolves.**

