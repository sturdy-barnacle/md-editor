//
//  PluginManifest.swift
//  tibok
//
//  Plugin manifest format for describing third-party plugins.
//
//  MIT License - See LICENSE file in Plugins directory
//

import Foundation

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

    /// Author name
    let author: String?

    /// Minimum required tibok version (semantic versioning)
    /// Example: "0.6.0"
    let minimumTibokVersion: String?

    /// Plugin capabilities/permissions
    /// Example: ["slash-commands", "export", "webhooks"]
    let capabilities: [String]?

    /// Entry point details
    let entryPoint: EntryPoint?

    /// Configuration schema for the plugin (JSON Schema format)
    let configSchema: [String: AnyCodable]?

    struct EntryPoint: Codable {
        /// For framework-based plugins: the framework name
        let framework: String?

        /// For script-based plugins: path to script
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
        case minimumTibokVersion
        case capabilities
        case entryPoint
        case configSchema
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
