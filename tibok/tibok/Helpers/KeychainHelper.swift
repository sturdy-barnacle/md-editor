//
//  KeychainHelper.swift
//  tibok
//
//  Secure storage for sensitive credentials using macOS Keychain Services.
//  Provides save, load, and delete operations for string values.
//

import Foundation
import Security

/// Helper for storing and retrieving sensitive data from the macOS Keychain
enum KeychainHelper {

    /// Save a string value to the Keychain
    /// - Parameters:
    ///   - value: The string value to save
    ///   - service: Service identifier (e.g., "com.tibok.wordpress")
    ///   - account: Account identifier (e.g., "application-password")
    static func save(_ value: String, service: String, account: String) {
        guard let data = value.data(using: .utf8) else {
            print("KeychainHelper: Failed to encode value as UTF-8")
            return
        }

        // Delete any existing item first
        delete(service: service, account: account)

        // Add new item
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            print("KeychainHelper: Save failed with status \(status)")
            return
        }
    }

    /// Load a string value from the Keychain
    /// - Parameters:
    ///   - service: Service identifier
    ///   - account: Account identifier
    /// - Returns: The stored string value, or nil if not found
    static func load(service: String, account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            if status != errSecItemNotFound {
                print("KeychainHelper: Load failed with status \(status)")
            }
            return nil
        }

        guard let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            print("KeychainHelper: Failed to decode data as UTF-8")
            return nil
        }

        return value
    }

    /// Delete a value from the Keychain
    /// - Parameters:
    ///   - service: Service identifier
    ///   - account: Account identifier
    static func delete(service: String, account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let status = SecItemDelete(query as CFDictionary)

        // errSecItemNotFound is expected if item doesn't exist
        if status != errSecSuccess && status != errSecItemNotFound {
            print("KeychainHelper: Delete failed with status \(status)")
        }
    }
}
