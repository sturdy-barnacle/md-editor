#!/usr/bin/env swift
//
//  tibok-sign
//  Plugin signing tool for Tibok plugin developers
//
//  Usage:
//    tibok-sign generate-keys           - Generate a new Ed25519 key pair
//    tibok-sign sign <plugin-path>      - Sign a plugin bundle
//    tibok-sign verify <plugin-path>    - Verify a plugin's signature
//
//  MIT License - See LICENSE file in Plugins directory
//

import Foundation
import CryptoKit

// MARK: - Command Line Interface

func printUsage() {
    print("""
    tibok-sign - Plugin Signing Tool for Tibok

    Usage:
      tibok-sign generate-keys [--output <dir>]  Generate a new Ed25519 key pair
      tibok-sign sign <plugin-path>              Sign a plugin bundle
      tibok-sign verify <plugin-path>            Verify a plugin's signature
      tibok-sign help                            Show this help message

    Examples:
      tibok-sign generate-keys --output ~/.tibok/keys
      tibok-sign sign ~/MyPlugin
      tibok-sign verify ~/Downloads/MyPlugin

    The private key should be kept secure and never shared.
    The public key should be submitted during plugin verification.
    """)
}

func main() {
    let args = CommandLine.arguments

    guard args.count >= 2 else {
        printUsage()
        exit(1)
    }

    let command = args[1]

    switch command {
    case "generate-keys":
        let outputDir = parseOutputDir(args: args) ?? FileManager.default.currentDirectoryPath
        generateKeys(outputDir: outputDir)

    case "sign":
        guard args.count >= 3 else {
            print("Error: Missing plugin path")
            print("Usage: tibok-sign sign <plugin-path>")
            exit(1)
        }
        signPlugin(path: args[2])

    case "verify":
        guard args.count >= 3 else {
            print("Error: Missing plugin path")
            print("Usage: tibok-sign verify <plugin-path>")
            exit(1)
        }
        verifyPlugin(path: args[2])

    case "help", "--help", "-h":
        printUsage()

    default:
        print("Error: Unknown command '\(command)'")
        printUsage()
        exit(1)
    }
}

func parseOutputDir(args: [String]) -> String? {
    if let idx = args.firstIndex(of: "--output"), idx + 1 < args.count {
        return args[idx + 1]
    }
    return nil
}

// MARK: - Key Generation

func generateKeys(outputDir: String) {
    print("Generating Ed25519 key pair...")

    // Generate key pair
    let privateKey = Curve25519.Signing.PrivateKey()
    let publicKey = privateKey.publicKey

    // Encode keys as Base64
    let privateKeyBase64 = privateKey.rawRepresentation.base64EncodedString()
    let publicKeyBase64 = publicKey.rawRepresentation.base64EncodedString()

    // Create output directory if needed
    let outputURL = URL(fileURLWithPath: outputDir)
    do {
        try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)
    } catch {
        print("Error: Failed to create output directory: \(error.localizedDescription)")
        exit(1)
    }

    // Write private key
    let privateKeyPath = outputURL.appendingPathComponent("tibok-signing-key.private")
    do {
        let privateKeyContent = """
        # Tibok Plugin Signing Private Key
        # KEEP THIS FILE SECURE - DO NOT SHARE OR COMMIT TO VERSION CONTROL
        # Generated: \(ISO8601DateFormatter().string(from: Date()))

        \(privateKeyBase64)
        """
        try privateKeyContent.write(to: privateKeyPath, atomically: true, encoding: .utf8)

        // Set restrictive permissions (owner read/write only)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: privateKeyPath.path)
    } catch {
        print("Error: Failed to write private key: \(error.localizedDescription)")
        exit(1)
    }

    // Write public key
    let publicKeyPath = outputURL.appendingPathComponent("tibok-signing-key.public")
    do {
        let publicKeyContent = """
        # Tibok Plugin Signing Public Key
        # Submit this key when registering for plugin verification
        # Generated: \(ISO8601DateFormatter().string(from: Date()))

        \(publicKeyBase64)
        """
        try publicKeyContent.write(to: publicKeyPath, atomically: true, encoding: .utf8)
    } catch {
        print("Error: Failed to write public key: \(error.localizedDescription)")
        exit(1)
    }

    print("""

    ✅ Key pair generated successfully!

    Private key: \(privateKeyPath.path)
    Public key:  \(publicKeyPath.path)

    IMPORTANT:
    - Keep your private key secure. Never share it or commit it to version control.
    - Submit your public key when applying for plugin verification.
    - Back up your private key in a secure location.

    Next steps:
    1. Sign your plugin: tibok-sign sign <plugin-path>
    2. Apply for verification at https://plugins.tibok.app/verify

    """)
}

// MARK: - Plugin Signing

func signPlugin(path: String) {
    let pluginURL = URL(fileURLWithPath: path)

    // Read manifest
    let manifestURL = pluginURL.appendingPathComponent("manifest.json")
    guard FileManager.default.fileExists(atPath: manifestURL.path) else {
        print("Error: manifest.json not found at \(manifestURL.path)")
        exit(1)
    }

    guard let manifestData = try? Data(contentsOf: manifestURL),
          var manifest = try? JSONDecoder().decode(Manifest.self, from: manifestData) else {
        print("Error: Failed to read or parse manifest.json")
        exit(1)
    }

    // Find private key
    let privateKeyPath = findPrivateKey()
    guard let privateKey = loadPrivateKey(from: privateKeyPath) else {
        print("Error: Failed to load private key from \(privateKeyPath)")
        exit(1)
    }

    print("Signing plugin: \(manifest.name) v\(manifest.version)")
    print("Using key from: \(privateKeyPath)")

    // Compute content hash
    let contentHash = computeContentHash(pluginURL: pluginURL)
    print("Content hash: \(contentHash)")

    // Create signed message
    let signedMessage = "tibok-plugin-v1:\(manifest.identifier):\(manifest.version):\(contentHash)"
    let signedData = Data(signedMessage.utf8)

    // Sign the message
    guard let signatureData = try? privateKey.signature(for: signedData) else {
        print("Error: Failed to create signature")
        exit(1)
    }

    let signatureBase64 = signatureData.base64EncodedString()
    let publicKeyBase64 = privateKey.publicKey.rawRepresentation.base64EncodedString()

    // Update manifest with signature
    manifest.signature = SignatureInfo(
        algorithm: "ed25519",
        publicKey: publicKeyBase64,
        signature: signatureBase64,
        signedAt: ISO8601DateFormatter().string(from: Date()),
        contentHash: contentHash
    )

    // Write updated manifest
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    guard let updatedManifestData = try? encoder.encode(manifest) else {
        print("Error: Failed to encode updated manifest")
        exit(1)
    }

    do {
        try updatedManifestData.write(to: manifestURL)
    } catch {
        print("Error: Failed to write manifest: \(error.localizedDescription)")
        exit(1)
    }

    print("""

    ✅ Plugin signed successfully!

    Signature: \(signatureBase64.prefix(32))...
    Public key: \(publicKeyBase64)

    The manifest.json has been updated with the signature.

    Next steps:
    1. Test locally: Install the plugin in Tibok
    2. Submit for verification at https://plugins.tibok.app/verify
    3. Provide your public key during verification

    """)
}

func findPrivateKey() -> String {
    let searchPaths = [
        FileManager.default.currentDirectoryPath + "/tibok-signing-key.private",
        NSHomeDirectory() + "/.tibok/keys/tibok-signing-key.private",
        NSHomeDirectory() + "/tibok-signing-key.private"
    ]

    for path in searchPaths {
        if FileManager.default.fileExists(atPath: path) {
            return path
        }
    }

    print("""
    Error: Private key not found.

    Searched in:
    \(searchPaths.joined(separator: "\n"))

    Generate a key pair first:
      tibok-sign generate-keys

    Or specify the key location with TIBOK_SIGNING_KEY environment variable.
    """)
    exit(1)
}

func loadPrivateKey(from path: String) -> Curve25519.Signing.PrivateKey? {
    guard let content = try? String(contentsOfFile: path, encoding: .utf8) else {
        return nil
    }

    // Extract base64 key (skip comment lines)
    let lines = content.split(separator: "\n")
    guard let keyLine = lines.first(where: { !$0.hasPrefix("#") && !$0.isEmpty }) else {
        return nil
    }

    guard let keyData = Data(base64Encoded: String(keyLine).trimmingCharacters(in: .whitespaces)) else {
        return nil
    }

    return try? Curve25519.Signing.PrivateKey(rawRepresentation: keyData)
}

func computeContentHash(pluginURL: URL) -> String {
    var hasher = SHA256()

    // Get all files in the plugin directory (excluding manifest.json signature field)
    let files = gatherFiles(at: pluginURL).sorted()

    for file in files {
        // Skip manifest.json (we hash it separately without the signature)
        if file.lastPathComponent == "manifest.json" {
            continue
        }

        if let data = try? Data(contentsOf: file) {
            hasher.update(data: data)
        }
    }

    // Include manifest content without signature
    let manifestURL = pluginURL.appendingPathComponent("manifest.json")
    if let manifestData = try? Data(contentsOf: manifestURL),
       var manifest = try? JSONDecoder().decode(Manifest.self, from: manifestData) {
        manifest.signature = nil
        if let cleanManifestData = try? JSONEncoder().encode(manifest) {
            hasher.update(data: cleanManifestData)
        }
    }

    let digest = hasher.finalize()
    return digest.map { String(format: "%02x", $0) }.joined()
}

func gatherFiles(at url: URL) -> [URL] {
    var files: [URL] = []
    let enumerator = FileManager.default.enumerator(
        at: url,
        includingPropertiesForKeys: [.isRegularFileKey],
        options: [.skipsHiddenFiles]
    )

    while let fileURL = enumerator?.nextObject() as? URL {
        if let isFile = try? fileURL.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile,
           isFile {
            files.append(fileURL)
        }
    }

    return files
}

// MARK: - Plugin Verification

func verifyPlugin(path: String) {
    let pluginURL = URL(fileURLWithPath: path)

    // Read manifest
    let manifestURL = pluginURL.appendingPathComponent("manifest.json")
    guard let manifestData = try? Data(contentsOf: manifestURL),
          let manifest = try? JSONDecoder().decode(Manifest.self, from: manifestData) else {
        print("Error: Failed to read manifest.json")
        exit(1)
    }

    print("Verifying plugin: \(manifest.name) v\(manifest.version)")

    guard let signature = manifest.signature else {
        print("❌ Plugin is not signed")
        exit(1)
    }

    // Load public key
    guard let publicKeyData = Data(base64Encoded: signature.publicKey),
          let publicKey = try? Curve25519.Signing.PublicKey(rawRepresentation: publicKeyData) else {
        print("❌ Invalid public key in signature")
        exit(1)
    }

    // Compute content hash
    let expectedHash = computeContentHash(pluginURL: pluginURL)
    print("Expected hash: \(expectedHash)")
    print("Stored hash:   \(signature.contentHash)")

    guard expectedHash == signature.contentHash else {
        print("❌ Content hash mismatch - plugin files may have been modified")
        exit(1)
    }

    // Verify signature
    let signedMessage = "tibok-plugin-v1:\(manifest.identifier):\(manifest.version):\(signature.contentHash)"
    let signedData = Data(signedMessage.utf8)

    guard let signatureData = Data(base64Encoded: signature.signature) else {
        print("❌ Invalid signature format")
        exit(1)
    }

    let isValid = publicKey.isValidSignature(signatureData, for: signedData)

    if isValid {
        print("""

        ✅ Signature is valid!

        Plugin: \(manifest.name)
        Version: \(manifest.version)
        Signed at: \(signature.signedAt ?? "Unknown")
        Public key: \(signature.publicKey.prefix(32))...

        """)
    } else {
        print("❌ Signature verification failed")
        exit(1)
    }
}

// MARK: - Data Models

struct Manifest: Codable {
    let identifier: String
    let name: String
    let version: String
    var signature: SignatureInfo?

    // Pass through other fields
    let description: String?
    let icon: String?
    let author: String?
    let minimumTibokVersion: String?
    let pluginType: String?
    let permissions: [String]?
    let trustTier: String?
    let homepage: String?
    let repository: String?
    let license: String?
    let keywords: [String]?
    let entryPoint: EntryPoint?

    enum CodingKeys: String, CodingKey {
        case identifier, name, version, signature
        case description, icon, author
        case minimumTibokVersion = "minimum_tibok_version"
        case pluginType = "plugin_type"
        case permissions
        case trustTier = "trust_tier"
        case homepage, repository, license, keywords
        case entryPoint = "entry_point"
    }
}

struct SignatureInfo: Codable {
    let algorithm: String
    let publicKey: String
    let signature: String
    let signedAt: String?
    let contentHash: String

    enum CodingKeys: String, CodingKey {
        case algorithm
        case publicKey = "public_key"
        case signature
        case signedAt = "signed_at"
        case contentHash = "content_hash"
    }
}

struct EntryPoint: Codable {
    let main: String?
    let framework: String?
    let className: String?

    enum CodingKeys: String, CodingKey {
        case main
        case framework
        case className = "class_name"
    }
}

// MARK: - Entry Point

main()
