//
//  SignatureVerifier.swift
//  tibok
//
//  Verifies cryptographic signatures on verified plugins.
//
//  MIT License - See LICENSE file in Plugins directory
//

import Foundation
import CryptoKit

/// Verifies cryptographic signatures for verified plugins.
@MainActor
final class SignatureVerifier {
    static let shared = SignatureVerifier()

    /// Trusted public keys for signature verification
    private var trustedKeys: [String: Curve25519.Signing.PublicKey] = [:]

    /// Maximum age for a signature (30 days)
    private let maxSignatureAge: TimeInterval = 30 * 24 * 60 * 60

    private init() {
        loadTrustedKeys()
    }

    // MARK: - Key Management

    /// Load trusted public keys from embedded resources or remote
    private func loadTrustedKeys() {
        // Load the official Tibok signing key
        // In production, this would be loaded from a secure source
        if let officialKey = loadEmbeddedKey(id: "tibok-2026") {
            trustedKeys["tibok-2026"] = officialKey
        }

        // Additional keys can be loaded from a registry or keyserver
    }

    /// Load an embedded public key by ID
    private func loadEmbeddedKey(id: String) -> Curve25519.Signing.PublicKey? {
        // For now, return nil - keys will be configured when setting up the signing infrastructure
        // In production:
        // 1. Embed the public key in the app bundle
        // 2. Or fetch from a trusted registry at startup

        // Placeholder for the official key (32 bytes, base64 encoded)
        let officialPublicKeyBase64 = TrustedKeys.officialPublicKey

        guard !officialPublicKeyBase64.isEmpty,
              let keyData = Data(base64Encoded: officialPublicKeyBase64) else {
            return nil
        }

        do {
            return try Curve25519.Signing.PublicKey(rawRepresentation: keyData)
        } catch {
            print("Failed to load public key \(id): \(error)")
            return nil
        }
    }

    /// Add a trusted public key at runtime (for testing or key rotation)
    func addTrustedKey(id: String, publicKey: Curve25519.Signing.PublicKey) {
        trustedKeys[id] = publicKey
    }

    /// Remove a trusted key (for key revocation)
    func removeTrustedKey(id: String) {
        trustedKeys.removeValue(forKey: id)
    }

    // MARK: - Signature Verification

    /// Verify a plugin's signature
    func verify(manifest: PluginManifest, bundleData: Data) -> SignatureVerificationResult {
        guard let signature = manifest.signature else {
            return .noSignature
        }

        // Check algorithm is supported
        guard signature.algorithm == "ed25519" else {
            return .unsupportedAlgorithm(signature.algorithm)
        }

        // Check we have the public key
        guard let publicKey = trustedKeys[signature.publicKeyId] else {
            return .unknownKey(signature.publicKeyId)
        }

        // Verify signature age
        if let signedDate = parseDate(signature.signedAt) {
            let age = Date().timeIntervalSince(signedDate)
            if age > maxSignatureAge {
                return .signatureExpired(signedAt: signedDate)
            }
        }

        // Decode signature
        guard let signatureData = Data(base64Encoded: signature.signature) else {
            return .invalidSignature("Signature is not valid base64")
        }

        // Compute content hash
        let computedHash = SHA256.hash(data: bundleData)
        let computedHashHex = computedHash.compactMap { String(format: "%02x", $0) }.joined()

        // Verify content hash matches (if provided in signature)
        if let expectedHash = signature.contentHash {
            guard computedHashHex == expectedHash else {
                return .hashMismatch(expected: expectedHash, actual: computedHashHex)
            }
        }

        // Create the message that was signed: "tibok-plugin-v1:<identifier>:<version>:<hash>"
        let message = "tibok-plugin-v1:\(manifest.identifier):\(manifest.version):\(computedHashHex)"
        guard let messageData = message.data(using: .utf8) else {
            return .invalidSignature("Failed to encode message")
        }

        // Verify the signature
        do {
            let isValid = publicKey.isValidSignature(signatureData, for: messageData)
            if isValid {
                return .valid(keyId: signature.publicKeyId)
            } else {
                return .invalidSignature("Signature verification failed")
            }
        }
    }

    /// Convenience method to check if a manifest has a valid signature
    func isValid(manifest: PluginManifest, bundleData: Data) -> Bool {
        let result = verify(manifest: manifest, bundleData: bundleData)
        return result.isValid
    }

    // MARK: - Helpers

    private func parseDate(_ isoString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: isoString) ?? ISO8601DateFormatter().date(from: isoString)
    }
}

// MARK: - Verification Result

/// Result of signature verification
enum SignatureVerificationResult {
    /// Signature is valid
    case valid(keyId: String)

    /// Plugin has no signature (community plugin)
    case noSignature

    /// Signature algorithm is not supported
    case unsupportedAlgorithm(String)

    /// Public key is not in trusted keys
    case unknownKey(String)

    /// Signature has expired
    case signatureExpired(signedAt: Date)

    /// Content hash doesn't match
    case hashMismatch(expected: String, actual: String)

    /// Signature is invalid or malformed
    case invalidSignature(String)

    var isValid: Bool {
        if case .valid = self { return true }
        return false
    }

    var localizedDescription: String {
        switch self {
        case .valid(let keyId):
            return "Signature verified with key: \(keyId)"
        case .noSignature:
            return "Plugin is not signed"
        case .unsupportedAlgorithm(let algo):
            return "Unsupported signature algorithm: \(algo)"
        case .unknownKey(let keyId):
            return "Unknown signing key: \(keyId)"
        case .signatureExpired(let date):
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return "Signature expired (signed: \(formatter.string(from: date)))"
        case .hashMismatch(let expected, let actual):
            return "Content hash mismatch (expected: \(expected.prefix(8))..., got: \(actual.prefix(8))...)"
        case .invalidSignature(let reason):
            return "Invalid signature: \(reason)"
        }
    }
}

// MARK: - Trusted Keys

/// Embedded trusted public keys for signature verification
enum TrustedKeys {
    /// The official Tibok signing public key (base64-encoded Ed25519)
    /// This will be replaced with the actual key when the signing infrastructure is set up
    static let officialPublicKey = ""

    /// Key ID for the official key
    static let officialKeyId = "tibok-2026"
}

// MARK: - Signing (for development/testing)

#if DEBUG
/// Helper for generating test signatures during development
extension SignatureVerifier {
    /// Generate a keypair for testing
    static func generateTestKeypair() -> (privateKey: Curve25519.Signing.PrivateKey, publicKey: Curve25519.Signing.PublicKey) {
        let privateKey = Curve25519.Signing.PrivateKey()
        return (privateKey, privateKey.publicKey)
    }

    /// Sign a plugin for testing
    static func signForTesting(
        manifest: PluginManifest,
        bundleData: Data,
        privateKey: Curve25519.Signing.PrivateKey,
        keyId: String = "test-key"
    ) -> PluginSignature? {
        // Compute content hash
        let hash = SHA256.hash(data: bundleData)
        let hashHex = hash.compactMap { String(format: "%02x", $0) }.joined()

        // Create message
        let message = "tibok-plugin-v1:\(manifest.identifier):\(manifest.version):\(hashHex)"
        guard let messageData = message.data(using: .utf8) else { return nil }

        // Sign
        do {
            let signature = try privateKey.signature(for: messageData)
            let signatureBase64 = signature.base64EncodedString()

            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime]

            return PluginSignature(
                algorithm: "ed25519",
                publicKeyId: keyId,
                signature: signatureBase64,
                signedAt: formatter.string(from: Date()),
                contentHash: hashHex
            )
        } catch {
            print("Failed to sign: \(error)")
            return nil
        }
    }
}
#endif
