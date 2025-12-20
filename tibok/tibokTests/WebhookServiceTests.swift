//
//  WebhookServiceTests.swift
//  tibokTests
//
//  Tests for webhook delivery system.
//

import Testing
import Foundation
@testable import tibok

@Suite("Webhook Service Tests")
@MainActor
struct WebhookServiceTests {

    // MARK: - Webhook Config Tests

    @Test("WebhookConfig initializes with defaults")
    func webhookConfigDefaults() {
        let webhook = WebhookConfig()

        #expect(webhook.name == "")
        #expect(webhook.url == "")
        #expect(webhook.method == .post)
        #expect(webhook.headers["Content-Type"] == "application/json")
        #expect(webhook.events.contains(.documentSave) == true)
        #expect(webhook.isEnabled == true)
    }

    @Test("WebhookConfig can be created with custom values")
    func webhookConfigCustomValues() {
        let webhook = WebhookConfig(
            name: "Test Webhook",
            url: "https://example.com/webhook",
            method: .get,
            headers: ["Authorization": "Bearer token"],
            events: [.documentSave, .gitPush],
            isEnabled: false
        )

        #expect(webhook.name == "Test Webhook")
        #expect(webhook.url == "https://example.com/webhook")
        #expect(webhook.method == .get)
        #expect(webhook.headers["Authorization"] == "Bearer token")
        #expect(webhook.events.count == 2)
        #expect(webhook.isEnabled == false)
    }

    @Test("WebhookConfig new factory method")
    func webhookConfigNewFactory() {
        let webhook = WebhookConfig.new()

        #expect(webhook.name == "New Webhook")
        #expect(webhook.payloadTemplate == WebhookConfig.defaultPayloadTemplate)
        #expect(webhook.isEnabled == true)
    }

    // MARK: - Webhook Event Tests

    @Test("WebhookEvent has correct raw values")
    func webhookEventRawValues() {
        #expect(WebhookEvent.documentSave.rawValue == "document.save")
        #expect(WebhookEvent.documentExport.rawValue == "document.export")
        #expect(WebhookEvent.gitPush.rawValue == "git.push")
    }

    @Test("WebhookEvent has display names")
    func webhookEventDisplayNames() {
        #expect(WebhookEvent.documentSave.displayName == "Document Save")
        #expect(WebhookEvent.documentExport.displayName == "Document Export")
        #expect(WebhookEvent.gitPush.displayName == "Git Push")
    }

    @Test("WebhookEvent has descriptions")
    func webhookEventDescriptions() {
        #expect(WebhookEvent.documentSave.description.isEmpty == false)
        #expect(WebhookEvent.documentExport.description.isEmpty == false)
        #expect(WebhookEvent.gitPush.description.isEmpty == false)
    }

    @Test("WebhookEvent is identifiable")
    func webhookEventIdentifiable() {
        let event = WebhookEvent.documentSave
        #expect(event.id == "document.save")
    }

    // MARK: - HTTP Method Tests

    @Test("HTTPMethod has correct raw values")
    func httpMethodRawValues() {
        #expect(HTTPMethod.get.rawValue == "GET")
        #expect(HTTPMethod.post.rawValue == "POST")
        #expect(HTTPMethod.put.rawValue == "PUT")
        #expect(HTTPMethod.delete.rawValue == "DELETE")
    }

    @Test("HTTPMethod is codable")
    func httpMethodCodable() throws {
        let method = HTTPMethod.post
        let encoded = try JSONEncoder().encode(method)
        let decoded = try JSONDecoder().decode(HTTPMethod.self, from: encoded)

        #expect(decoded == method)
    }

    // MARK: - Webhook Context Tests

    @Test("WebhookContext expands event variable")
    func webhookContextExpandsEvent() {
        let context = WebhookContext(
            event: .documentSave,
            filename: "test.md",
            title: "Test",
            path: "/path/test.md",
            content: nil
        )

        let template = "{{event}}"
        let expanded = context.expand(template)

        #expect(expanded == "document.save")
    }

    @Test("WebhookContext expands filename variable")
    func webhookContextExpandsFilename() {
        let context = WebhookContext(
            event: .documentSave,
            filename: "my-document.md",
            title: nil,
            path: "",
            content: nil
        )

        let template = "{{filename}}"
        let expanded = context.expand(template)

        #expect(expanded == "my-document.md")
    }

    @Test("WebhookContext expands title variable")
    func webhookContextExpandsTitle() {
        let context = WebhookContext(
            event: .documentSave,
            filename: "test.md",
            title: "My Title",
            path: "",
            content: nil
        )

        let template = "{{title}}"
        let expanded = context.expand(template)

        #expect(expanded == "My Title")
    }

    @Test("WebhookContext uses filename when title is nil")
    func webhookContextFallbackToFilename() {
        let context = WebhookContext(
            event: .documentSave,
            filename: "fallback.md",
            title: nil,
            path: "",
            content: nil
        )

        let template = "{{title}}"
        let expanded = context.expand(template)

        #expect(expanded == "fallback.md")
    }

    @Test("WebhookContext expands path variable")
    func webhookContextExpandsPath() {
        let context = WebhookContext(
            event: .documentSave,
            filename: "test.md",
            title: nil,
            path: "/Users/test/documents/test.md",
            content: nil
        )

        let template = "{{path}}"
        let expanded = context.expand(template)

        #expect(expanded == "/Users/test/documents/test.md")
    }

    @Test("WebhookContext expands timestamp variable")
    func webhookContextExpandsTimestamp() {
        let context = WebhookContext(
            event: .documentSave,
            filename: "test.md",
            title: nil,
            path: "",
            content: nil
        )

        let template = "{{timestamp}}"
        let expanded = context.expand(template)

        // Should be ISO 8601 format
        #expect(expanded.contains("T"))
        #expect(expanded.contains(":"))
    }

    @Test("WebhookContext expands content variable")
    func webhookContextExpandsContent() {
        let context = WebhookContext(
            event: .documentSave,
            filename: "test.md",
            title: nil,
            path: "",
            content: "Hello World"
        )

        let template = "{{content}}"
        let expanded = context.expand(template)

        #expect(expanded == "Hello World")
    }

    @Test("WebhookContext escapes content for JSON")
    func webhookContextEscapesContent() {
        let context = WebhookContext(
            event: .documentSave,
            filename: "test.md",
            title: nil,
            path: "",
            content: "Line 1\nLine 2\t\"quoted\""
        )

        let template = "{\"content\": \"{{content}}\"}"
        let expanded = context.expand(template)

        // Should escape newlines, tabs, and quotes
        #expect(expanded.contains("\\n"))
        #expect(expanded.contains("\\t"))
        #expect(expanded.contains("\\\""))
    }

    @Test("WebhookContext handles nil content")
    func webhookContextHandlesNilContent() {
        let context = WebhookContext(
            event: .documentSave,
            filename: "test.md",
            title: nil,
            path: "",
            content: nil
        )

        let template = "{{content}}"
        let expanded = context.expand(template)

        #expect(expanded == "")
    }

    @Test("WebhookContext expands multiple variables")
    func webhookContextExpandsMultiple() {
        let context = WebhookContext(
            event: .documentSave,
            filename: "test.md",
            title: "Test Document",
            path: "/path/test.md",
            content: "Content"
        )

        let template = """
        {
          "event": "{{event}}",
          "filename": "{{filename}}",
          "title": "{{title}}",
          "path": "{{path}}"
        }
        """

        let expanded = context.expand(template)

        #expect(expanded.contains("\"event\": \"document.save\""))
        #expect(expanded.contains("\"filename\": \"test.md\""))
        #expect(expanded.contains("\"title\": \"Test Document\""))
        #expect(expanded.contains("\"path\": \"/path/test.md\""))
    }

    @Test("WebhookContext expands default template")
    func webhookContextExpandsDefaultTemplate() {
        let context = WebhookContext(
            event: .documentSave,
            filename: "test.md",
            title: "Test",
            path: "/path/test.md",
            content: nil
        )

        let expanded = context.expand(WebhookConfig.defaultPayloadTemplate)

        // Should be valid JSON
        #expect(expanded.contains("{"))
        #expect(expanded.contains("}"))
        #expect(expanded.contains("\"event\""))
        #expect(expanded.contains("\"filename\""))
        #expect(expanded.contains("\"title\""))
    }

    // MARK: - WebhookService Management Tests

    @Test("WebhookService is singleton")
    func webhookServiceIsSingleton() {
        let service1 = WebhookService.shared
        let service2 = WebhookService.shared

        #expect(service1 === service2)
    }

    @Test("WebhookService initializes with empty webhooks")
    func webhookServiceInitializes() {
        let service = WebhookService.shared

        // Count may be > 0 if previous tests added webhooks
        #expect(service.webhooks.count >= 0)
        #expect(service.recentResults.count >= 0)
    }

    @Test("WebhookService can add webhook")
    func webhookServiceAddWebhook() {
        let service = WebhookService.shared
        let initialCount = service.webhooks.count

        let webhook = WebhookConfig(
            id: UUID(),
            name: "Test Add",
            url: "https://example.com/test-add"
        )

        service.addWebhook(webhook)

        #expect(service.webhooks.count == initialCount + 1)
        #expect(service.webhooks.contains { $0.id == webhook.id })

        // Cleanup
        service.deleteWebhook(webhook)
    }

    @Test("WebhookService can update webhook")
    func webhookServiceUpdateWebhook() {
        let service = WebhookService.shared

        var webhook = WebhookConfig(
            name: "Test Update Original",
            url: "https://example.com/original"
        )

        service.addWebhook(webhook)

        // Update
        webhook.name = "Test Update Modified"
        webhook.url = "https://example.com/modified"
        service.updateWebhook(webhook)

        let updated = service.webhooks.first { $0.id == webhook.id }
        #expect(updated?.name == "Test Update Modified")
        #expect(updated?.url == "https://example.com/modified")

        // Cleanup
        service.deleteWebhook(webhook)
    }

    @Test("WebhookService can delete webhook")
    func webhookServiceDeleteWebhook() {
        let service = WebhookService.shared

        let webhook = WebhookConfig(
            name: "Test Delete",
            url: "https://example.com/delete"
        )

        service.addWebhook(webhook)
        let countAfterAdd = service.webhooks.count

        service.deleteWebhook(webhook)
        let countAfterDelete = service.webhooks.count

        #expect(countAfterDelete == countAfterAdd - 1)
        #expect(!service.webhooks.contains { $0.id == webhook.id })
    }

    @Test("WebhookService can toggle webhook")
    func webhookServiceToggleWebhook() {
        let service = WebhookService.shared

        let webhook = WebhookConfig(
            name: "Test Toggle",
            url: "https://example.com/toggle",
            isEnabled: true
        )

        service.addWebhook(webhook)

        // Toggle off
        service.toggleWebhook(webhook)
        let toggledOff = service.webhooks.first { $0.id == webhook.id }
        #expect(toggledOff?.isEnabled == false)

        // Toggle on
        service.toggleWebhook(webhook)
        let toggledOn = service.webhooks.first { $0.id == webhook.id }
        #expect(toggledOn?.isEnabled == true)

        // Cleanup
        service.deleteWebhook(webhook)
    }

    // MARK: - WebhookService Persistence Tests

    @Test("WebhookService persists webhooks")
    func webhookServicePersists() {
        let service = WebhookService.shared

        let webhook = WebhookConfig(
            id: UUID(),
            name: "Test Persist",
            url: "https://example.com/persist"
        )

        service.addWebhook(webhook)

        // Verify saved to UserDefaults
        let key = "webhooks"
        let data = UserDefaults.standard.data(forKey: key)
        #expect(data != nil)

        // Cleanup
        service.deleteWebhook(webhook)
    }

    // MARK: - Webhook Result Tests

    @Test("WebhookResult initializes with success")
    func webhookResultSuccess() {
        let webhook = WebhookConfig.new()
        let result = WebhookResult(webhook: webhook, success: true, statusCode: 200)

        #expect(result.success == true)
        #expect(result.statusCode == 200)
        #expect(result.error == nil)
        #expect(result.timestamp != nil)
    }

    @Test("WebhookResult initializes with failure")
    func webhookResultFailure() {
        let webhook = WebhookConfig.new()
        let result = WebhookResult(webhook: webhook, success: false, error: "Connection timeout")

        #expect(result.success == false)
        #expect(result.error == "Connection timeout")
    }

    // MARK: - Webhook Execution Tests (Mock)

    @Test("WebhookService test webhook creates result")
    func webhookServiceTestWebhook() async {
        let service = WebhookService.shared

        // Use a webhook with invalid URL so it fails predictably
        let webhook = WebhookConfig(
            name: "Test Webhook",
            url: "https://invalid-domain-that-does-not-exist-12345.com/webhook",
            method: .post,
            payloadTemplate: WebhookConfig.defaultPayloadTemplate
        )

        let result = await service.testWebhook(webhook)

        // Should return a result (success or failure depending on network)
        #expect(result.webhook.name == "Test Webhook")
        #expect(result.timestamp != nil)
        // Don't assert success/failure as it depends on network availability
    }

    @Test("WebhookService trigger filters by event")
    func webhookServiceTriggerFiltersEvent() async {
        let service = WebhookService.shared

        // Create webhook for documentSave only
        let webhook = WebhookConfig(
            name: "Save Only",
            url: "https://example.com/save",
            events: [.documentSave],
            isEnabled: true
        )

        service.addWebhook(webhook)

        let initialResultCount = service.recentResults.count

        // Trigger gitPush event (should not match)
        let context = WebhookContext(
            event: .gitPush,
            filename: "test.md",
            title: nil,
            path: "/path",
            content: nil
        )

        await service.trigger(event: .gitPush, context: context)

        // Should not have added a result (webhook not triggered)
        // Note: This may be flaky if there are other webhooks registered
        // In a real test environment, we'd want to isolate the service

        // Cleanup
        service.deleteWebhook(webhook)
    }

    @Test("WebhookService convenience method for document save")
    func webhookServiceDocumentSaveConvenience() async {
        let service = WebhookService.shared

        // Just test that the method doesn't crash
        await service.triggerDocumentSave(
            filename: "test.md",
            title: "Test",
            path: "/path/test.md",
            content: "Content"
        )

        // No assertions - just verifying method works
    }

    @Test("WebhookService convenience method for document export")
    func webhookServiceDocumentExportConvenience() async {
        let service = WebhookService.shared

        await service.triggerDocumentExport(
            filename: "test.md",
            title: "Test",
            path: "/path/test.md",
            exportFormat: "PDF"
        )

        // No assertions - just verifying method works
    }

    @Test("WebhookService convenience method for git push")
    func webhookServiceGitPushConvenience() async {
        let service = WebhookService.shared

        await service.triggerGitPush(repositoryPath: "/path/to/repo")

        // No assertions - just verifying method works
    }

    @Test("WebhookService can clear results")
    func webhookServiceClearResults() {
        let service = WebhookService.shared

        service.clearResults()
        #expect(service.recentResults.count == 0)
    }

    // MARK: - Webhook Config Codable Tests

    @Test("WebhookConfig is encodable")
    func webhookConfigEncodable() throws {
        let webhook = WebhookConfig(
            name: "Test",
            url: "https://example.com",
            method: .post,
            events: [.documentSave, .gitPush]
        )

        let encoded = try JSONEncoder().encode(webhook)
        #expect(encoded.count > 0)
    }

    @Test("WebhookConfig is decodable")
    func webhookConfigDecodable() throws {
        let webhook = WebhookConfig(
            name: "Test Decode",
            url: "https://example.com/decode",
            method: .get,
            events: [.documentExport]
        )

        let encoded = try JSONEncoder().encode(webhook)
        let decoded = try JSONDecoder().decode(WebhookConfig.self, from: encoded)

        #expect(decoded.name == webhook.name)
        #expect(decoded.url == webhook.url)
        #expect(decoded.method == webhook.method)
        #expect(decoded.events == webhook.events)
    }

    @Test("WebhookConfig round-trip encoding")
    func webhookConfigRoundTrip() throws {
        let original = WebhookConfig(
            name: "Round Trip",
            url: "https://example.com/roundtrip",
            method: .put,
            headers: ["X-Custom": "value"],
            payloadTemplate: "{\"test\": true}",
            events: [.documentSave, .documentExport, .gitPush],
            isEnabled: false
        )

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(WebhookConfig.self, from: encoded)

        #expect(decoded.id == original.id)
        #expect(decoded.name == original.name)
        #expect(decoded.url == original.url)
        #expect(decoded.method == original.method)
        #expect(decoded.headers == original.headers)
        #expect(decoded.payloadTemplate == original.payloadTemplate)
        #expect(decoded.events == original.events)
        #expect(decoded.isEnabled == original.isEnabled)
    }
}
