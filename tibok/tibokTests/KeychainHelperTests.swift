//
//  KeychainHelperTests.swift
//  tibokTests
//
//  Tests for the KeychainHelper (Keychain Services wrapper).
//  Note: Keychain tests may behave differently depending on code signing.
//

import Foundation
import Testing
@testable import tibok

@Suite("Keychain Helper Tests")
struct KeychainHelperTests {

    let testService = "com.tibok.test"
    let testAccount = "test-account"

    @Test("Save and retrieve value")
    func saveAndRetrieveValue() {
        let testValue = "test-value-\(UUID().uuidString)"

        // Save
        KeychainHelper.save(testValue, service: testService, account: testAccount)

        // Clean up after test
        defer {
            KeychainHelper.delete(service: testService, account: testAccount)
        }

        // Retrieve
        let retrieved = KeychainHelper.load(service: testService, account: testAccount)
        #expect(retrieved == testValue)
    }

    @Test("Delete removes value")
    func deleteRemovesValue() {
        let testValue = "test-value-\(UUID().uuidString)"

        // Save a value
        KeychainHelper.save(testValue, service: testService, account: testAccount)

        // Verify it was saved
        let beforeDelete = KeychainHelper.load(service: testService, account: testAccount)
        #expect(beforeDelete == testValue)

        // Delete
        KeychainHelper.delete(service: testService, account: testAccount)

        // Verify it's gone
        let afterDelete = KeychainHelper.load(service: testService, account: testAccount)
        #expect(afterDelete == nil)
    }
}
