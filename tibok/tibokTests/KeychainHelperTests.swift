//
//  KeychainHelperTests.swift
//  tibokTests
//
//  Tests for the KeychainHelper (API key storage).
//  Note: Keychain tests may behave differently depending on code signing.
//

import Testing
@testable import tibok

@Suite("Keychain Helper Tests")
struct KeychainHelperTests {

    let testProvider = AIProviderType.claude

    @Test("Save and retrieve API key")
    func saveAndRetrieveAPIKey() {
        let testKey = "test-api-key-\(UUID().uuidString)"

        // Save
        let saveResult = KeychainHelper.shared.setAPIKey(testKey, for: testProvider)

        // Clean up after test
        defer {
            _ = KeychainHelper.shared.deleteAPIKey(for: testProvider)
        }

        // Verify save worked
        #expect(saveResult == true)

        // Retrieve
        let retrieved = KeychainHelper.shared.getAPIKey(for: testProvider)
        #expect(retrieved == testKey)
    }

    @Test("Has API key check")
    func hasAPIKey() {
        // Clean up first
        _ = KeychainHelper.shared.deleteAPIKey(for: testProvider)

        // Initially no key
        let hasKeyBefore = KeychainHelper.shared.hasAPIKey(for: testProvider)

        // Save a key
        _ = KeychainHelper.shared.setAPIKey("test-key-\(UUID().uuidString)", for: testProvider)

        // Clean up after test
        defer {
            _ = KeychainHelper.shared.deleteAPIKey(for: testProvider)
        }

        // Now should have key
        let hasKeyAfter = KeychainHelper.shared.hasAPIKey(for: testProvider)

        #expect(hasKeyBefore == false)
        #expect(hasKeyAfter == true)
    }
}
