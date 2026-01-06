//
//  PluginManifest.swift
//  tibok
//
//  Plugin manifest format for describing third-party plugins.
//
//  MIT License - See LICENSE file in Plugins directory
//

import Foundation

// MARK: - Plugin Type

/// The type of plugin (native Swift or script-based).
///
/// **Note:** Native plugins are reserved for official/built-in plugins only.
/// The marketplace and community plugins use script (JavaScript) exclusively.
enum PluginType: String, Codable {
    /// Native Swift framework plugin (.framework bundle).
    /// **Internal use only** - used for built-in plugins compiled into the app.
    case native = "native"

    /// JavaScript-based plugin (runs in JavaScriptCore sandbox).
    /// This is the only type available for marketplace/community plugins.
    case script = "script"

    var displayName: String {
        switch self {
        case .native: return "Native (Swift)"
        case .script: return "Script (JavaScript)"
        }
    }

    var icon: String {
        switch self {
        case .native: return "swift"
        case .script: return "curlybraces"
        }
    }
}

// MARK: - Trust Tier

/// The trust tier of a plugin, determining its verification status
enum PluginTrustTier: String, Codable {
    /// Official plugins compiled into the app
    case official = "official"

    /// Verified plugins that have been security audited and signed
    case verified = "verified"

    /// Community plugins that require user approval
    case community = "community"

    var displayName: String {
        switch self {
        case .official: return "Official"
        case .verified: return "Verified"
        case .community: return "Community"
        }
    }

    var description: String {
        switch self {
        case .official: return "Built into Tibok"
        case .verified: return "Security audited and signed"
        case .community: return "User-installed, not verified"
        }
    }

    var icon: String {
        switch self {
        case .official: return "checkmark.seal.fill"
        case .verified: return "checkmark.shield.fill"
        case .community: return "person.2.fill"
        }
    }

    var badgeColor: String {
        switch self {
        case .official: return "blue"
        case .verified: return "green"
        case .community: return "orange"
        }
    }
}

// MARK: - Plugin Signature

/// Cryptographic signature for verified plugins
struct PluginSignature: Codable, Hashable {
    /// Signature algorithm used (e.g., "ed25519")
    let algorithm: String

    /// ID of the public key used for signing (for key rotation)
    let publicKeyId: String

    /// Base64-encoded signature of the plugin bundle hash
    let signature: String

    /// When the plugin was signed (ISO 8601 format)
    let signedAt: String

    /// Hash of the signed content (for verification)
    let contentHash: String?

    enum CodingKeys: String, CodingKey {
        case algorithm
        case publicKeyId = "public_key_id"
        case signature
        case signedAt = "signed_at"
        case contentHash = "content_hash"
    }
}

// MARK: - Author Info

/// Detailed author information
struct PluginAuthorInfo: Codable, Hashable {
    /// Author name
    let name: String

    /// Author email (optional)
    let email: String?

    /// Author website or profile URL (optional)
    let url: String?

    init(name: String, email: String? = nil, url: String? = nil) {
        self.name = name
        self.email = email
        self.url = url
    }
}

// MARK: - Plugin Manifest

/// Manifest describing a third-party plugin.
/// Third-party plugins provide metadata via a manifest.json file,
/// while built-in plugins are compiled into the app.
struct PluginManifest: Codable {
    /// Unique identifier for the plugin (reverse-DNS style recommended)
    /// Example: "com.example.my-plugin"
    let identifier: String

    /// Human-readable name shown in UI
    let name: String

    /// Plugin version string (semantic versioning recommended)
    let version: String

    /// Optional description of what the plugin does
    let description: String?

    /// SF Symbol icon name for display in settings
    /// Defaults to "puzzlepiece.extension" if not provided
    let icon: String?

    /// Author name (simple string for backward compatibility)
    let author: String?

    /// Detailed author information (new format)
    let authorInfo: PluginAuthorInfo?

    /// Minimum required tibok version (semantic versioning)
    /// Example: "1.2.0"
    let minimumTibokVersion: String?

    /// Plugin type: native (Swift) or script (JavaScript)
    /// Defaults to native for backward compatibility
    let pluginType: PluginType?

    /// Permissions required by this plugin
    /// Must be declared for community plugins
    let permissions: [String]?

    /// Trust tier (set by registry, not by plugin author)
    /// This field is typically added by the marketplace, not the plugin author
    let trustTier: PluginTrustTier?

    /// Cryptographic signature (for verified plugins)
    let signature: PluginSignature?

    /// Legacy capabilities field (deprecated, use permissions instead)
    /// Example: ["slash-commands", "export", "webhooks"]
    let capabilities: [String]?

    /// Entry point details
    let entryPoint: EntryPoint?

    /// Configuration schema for the plugin (JSON Schema format)
    let configSchema: [String: AnyCodable]?

    /// Homepage URL for the plugin
    let homepage: String?

    /// Repository URL (e.g., GitHub)
    let repository: String?

    /// License identifier (e.g., "MIT", "Apache-2.0")
    let license: String?

    /// Keywords for search/discovery
    let keywords: [String]?

    struct EntryPoint: Codable {
        /// For framework-based plugins: the framework name
        let framework: String?

        /// For script-based plugins: path to main script file
        let script: String?

        /// Specified plugin class name (if framework has multiple)
        let className: String?
    }

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case identifier
        case name
        case version
        case description
        case icon
        case author
        case authorInfo = "author_info"
        case minimumTibokVersion = "minimum_tibok_version"
        case pluginType = "plugin_type"
        case permissions
        case trustTier = "trust_tier"
        case signature
        case capabilities
        case entryPoint = "entry_point"
        case configSchema = "config_schema"
        case homepage
        case repository
        case license
        case keywords
    }

    // MARK: - Validation

    /// Validates the manifest has required fields
    func isValid() -> Bool {
        return !identifier.isEmpty && !name.isEmpty && !version.isEmpty
    }

    /// Get the icon name, with fallback to default
    var iconName: String {
        icon ?? "puzzlepiece.extension"
    }

    /// Get the resolved plugin type (defaults to native)
    var resolvedPluginType: PluginType {
        pluginType ?? .native
    }

    /// Get the resolved trust tier (defaults to community)
    var resolvedTrustTier: PluginTrustTier {
        trustTier ?? .community
    }

    /// Get the resolved author name from either field
    var resolvedAuthorName: String? {
        authorInfo?.name ?? author
    }

    /// Parse permissions from string array to PluginPermission enum
    var parsedPermissions: [PluginPermission] {
        guard let permissions = permissions else { return [] }
        return permissions.compactMap { (permissionString: String) in
            PluginPermission(rawValue: permissionString)
        }
    }

    /// Get the permission set for this plugin
    var permissionSet: PluginPermissionSet {
        PluginPermissionSet(parsedPermissions)
    }

    /// Check if this plugin has elevated permissions
    var hasElevatedPermissions: Bool {
        permissionSet.hasElevatedPermissions
    }

    /// Check if this plugin is a script plugin requesting only safe permissions
    var isScriptCompatible: Bool {
        resolvedPluginType == .script && permissionSet.isScriptCompatible
    }

    /// Check if this is a verified (signed) plugin
    var isVerified: Bool {
        signature != nil && resolvedTrustTier == .verified
    }
}

/// Wrapper for encoding/decoding Any values in JSON
struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self.value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            self.value = bool
        } else if let int = try? container.decode(Int.self) {
            self.value = int
        } else if let double = try? container.decode(Double.self) {
            self.value = double
        } else if let string = try? container.decode(String.self) {
            self.value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            self.value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            self.value = dict.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode AnyCodable"
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        if value is NSNull {
            try container.encodeNil()
        } else if let bool = value as? Bool {
            try container.encode(bool)
        } else if let int = value as? Int {
            try container.encode(int)
        } else if let double = value as? Double {
            try container.encode(double)
        } else if let string = value as? String {
            try container.encode(string)
        } else if let array = value as? [Any] {
            try container.encode(array.map { AnyCodable($0) })
        } else if let dict = value as? [String: Any] {
            try container.encode(dict.mapValues { AnyCodable($0) })
        } else {
            throw EncodingError.invalidValue(
                value,
                EncodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Cannot encode \(type(of: value))"
                )
            )
        }
    }
}

