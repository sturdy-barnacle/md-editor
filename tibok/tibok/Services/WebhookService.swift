//
//  WebhookService.swift
//  tibok
//
//  Service for managing and executing webhooks.
//

import Foundation
import Combine

@MainActor
final class WebhookService: ObservableObject {
    static let shared = WebhookService()

    @Published var webhooks: [WebhookConfig] = []
    @Published var recentResults: [WebhookResult] = []

    private let userDefaultsKey = "webhooks"
    private let maxRecentResults = 50

    private init() {
        loadWebhooks()
    }

    // MARK: - Webhook Management

    func addWebhook(_ webhook: WebhookConfig) {
        webhooks.append(webhook)
        saveWebhooks()
    }

    func updateWebhook(_ webhook: WebhookConfig) {
        if let index = webhooks.firstIndex(where: { $0.id == webhook.id }) {
            webhooks[index] = webhook
            saveWebhooks()
        }
    }

    func deleteWebhook(_ webhook: WebhookConfig) {
        webhooks.removeAll { $0.id == webhook.id }
        saveWebhooks()
    }

    func deleteWebhook(at offsets: IndexSet) {
        webhooks.remove(atOffsets: offsets)
        saveWebhooks()
    }

    func toggleWebhook(_ webhook: WebhookConfig) {
        if let index = webhooks.firstIndex(where: { $0.id == webhook.id }) {
            webhooks[index].isEnabled.toggle()
            saveWebhooks()
        }
    }

    // MARK: - Persistence

    private func loadWebhooks() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            return
        }

        do {
            webhooks = try JSONDecoder().decode([WebhookConfig].self, from: data)
        } catch {
            print("Failed to load webhooks: \(error)")
        }
    }

    private func saveWebhooks() {
        do {
            let data = try JSONEncoder().encode(webhooks)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        } catch {
            print("Failed to save webhooks: \(error)")
        }
    }

    // MARK: - Event Triggering

    /// Trigger all webhooks registered for the given event
    func trigger(event: WebhookEvent, context: WebhookContext) async {
        let enabledWebhooks = webhooks.filter { $0.isEnabled && $0.events.contains(event) }

        for webhook in enabledWebhooks {
            let result = await executeWebhook(webhook, context: context)
            addResult(result)
        }
    }

    /// Convenience method to trigger document save webhooks
    func triggerDocumentSave(filename: String, title: String?, path: String, content: String? = nil) async {
        let context = WebhookContext(
            event: .documentSave,
            filename: filename,
            title: title,
            path: path,
            content: content
        )
        await trigger(event: .documentSave, context: context)
    }

    /// Convenience method to trigger document export webhooks
    func triggerDocumentExport(filename: String, title: String?, path: String, exportFormat: String) async {
        let context = WebhookContext(
            event: .documentExport,
            filename: filename,
            title: title,
            path: path,
            content: nil
        )
        await trigger(event: .documentExport, context: context)
    }

    /// Convenience method to trigger git push webhooks
    func triggerGitPush(repositoryPath: String) async {
        let context = WebhookContext(
            event: .gitPush,
            filename: "",
            title: nil,
            path: repositoryPath,
            content: nil
        )
        await trigger(event: .gitPush, context: context)
    }

    // MARK: - Webhook Execution

    /// Validate webhook URL to prevent SSRF attacks
    private func validateWebhookURL(_ urlString: String) -> (valid: Bool, error: String?) {
        guard let url = URL(string: urlString),
              let scheme = url.scheme?.lowercased(),
              scheme == "https",  // HTTPS only
              let host = url.host else {
            return (false, "Invalid URL or missing HTTPS scheme")
        }

        // Block private/reserved IP ranges
        let blockedPatterns = [
            "^localhost$", "^127\\..*", "^192\\.168\\..*",
            "^10\\..*", "^172\\.(1[6-9]|2[0-9]|3[01])\\..*",
            "^0\\.0\\.0\\.0$", "^169\\.254\\..*"
        ]

        for pattern in blockedPatterns {
            if host.range(of: pattern, options: .regularExpression) != nil {
                return (false, "Webhook URL blocked: private IP address or localhost not allowed")
            }
        }

        return (true, nil)
    }

    private func executeWebhook(_ webhook: WebhookConfig, context: WebhookContext) async -> WebhookResult {
        // Validate URL for security (SSRF protection)
        let validation = validateWebhookURL(webhook.url)
        guard validation.valid else {
            return WebhookResult(webhook: webhook, success: false, error: validation.error ?? "Invalid URL")
        }

        guard let url = URL(string: webhook.url) else {
            return WebhookResult(webhook: webhook, success: false, error: "Invalid URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = webhook.method.rawValue
        request.timeoutInterval = 30

        // Set headers
        for (key, value) in webhook.headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        // Set body for POST/PUT/DELETE
        if webhook.method != .get, let template = webhook.payloadTemplate {
            let payload = context.expand(template)
            request.httpBody = payload.data(using: .utf8)
        }

        do {
            let (_, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse {
                let success = (200...299).contains(httpResponse.statusCode)
                return WebhookResult(
                    webhook: webhook,
                    success: success,
                    statusCode: httpResponse.statusCode,
                    error: success ? nil : "HTTP \(httpResponse.statusCode)"
                )
            }

            return WebhookResult(webhook: webhook, success: true)
        } catch {
            return WebhookResult(
                webhook: webhook,
                success: false,
                error: error.localizedDescription
            )
        }
    }

    /// Test a webhook without saving it
    func testWebhook(_ webhook: WebhookConfig) async -> WebhookResult {
        let context = WebhookContext(
            event: webhook.events.first ?? .documentSave,
            filename: "test-document.md",
            title: "Test Document",
            path: "/path/to/test-document.md",
            content: "This is a test webhook payload."
        )

        return await executeWebhook(webhook, context: context)
    }

    // MARK: - Results Management

    private func addResult(_ result: WebhookResult) {
        recentResults.insert(result, at: 0)
        if recentResults.count > maxRecentResults {
            recentResults.removeLast()
        }
    }

    func clearResults() {
        recentResults.removeAll()
    }
}
