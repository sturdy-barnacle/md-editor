//
//  WebhookConfig.swift
//  tibok
//
//  Configuration model for webhooks that trigger on document events.
//

import Foundation

// MARK: - HTTP Method

enum HTTPMethod: String, Codable, CaseIterable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

// MARK: - Webhook Event

enum WebhookEvent: String, Codable, CaseIterable, Identifiable {
    case documentSave = "document.save"
    case documentExport = "document.export"
    case gitPush = "git.push"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .documentSave: return "Document Save"
        case .documentExport: return "Document Export"
        case .gitPush: return "Git Push"
        }
    }

    var description: String {
        switch self {
        case .documentSave: return "Triggered when a document is saved"
        case .documentExport: return "Triggered when exporting to PDF, HTML, etc."
        case .gitPush: return "Triggered after pushing to remote"
        }
    }
}

// MARK: - Webhook Config

struct WebhookConfig: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var url: String
    var method: HTTPMethod
    var headers: [String: String]
    var payloadTemplate: String?
    var events: Set<WebhookEvent>
    var isEnabled: Bool

    init(
        id: UUID = UUID(),
        name: String = "",
        url: String = "",
        method: HTTPMethod = .post,
        headers: [String: String] = ["Content-Type": "application/json"],
        payloadTemplate: String? = nil,
        events: Set<WebhookEvent> = [.documentSave],
        isEnabled: Bool = true
    ) {
        self.id = id
        self.name = name
        self.url = url
        self.method = method
        self.headers = headers
        self.payloadTemplate = payloadTemplate
        self.events = events
        self.isEnabled = isEnabled
    }

    /// Default payload template with common variables
    static let defaultPayloadTemplate = """
    {
      "event": "{{event}}",
      "filename": "{{filename}}",
      "title": "{{title}}",
      "path": "{{path}}",
      "timestamp": "{{timestamp}}"
    }
    """

    /// Create a new webhook with default values
    static func new() -> WebhookConfig {
        WebhookConfig(
            name: "New Webhook",
            payloadTemplate: defaultPayloadTemplate
        )
    }
}

// MARK: - Webhook Context

/// Context passed to webhooks for variable expansion
struct WebhookContext {
    let event: WebhookEvent
    let filename: String
    let title: String?
    let path: String
    let content: String?

    /// Expand template variables in a string
    func expand(_ template: String) -> String {
        var result = template
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime]

        result = result.replacingOccurrences(of: "{{event}}", with: event.rawValue)
        result = result.replacingOccurrences(of: "{{filename}}", with: filename)
        result = result.replacingOccurrences(of: "{{title}}", with: title ?? filename)
        result = result.replacingOccurrences(of: "{{path}}", with: path)
        result = result.replacingOccurrences(of: "{{timestamp}}", with: dateFormatter.string(from: Date()))

        if let content = content {
            // Escape content for JSON
            let escaped = content
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "\"", with: "\\\"")
                .replacingOccurrences(of: "\n", with: "\\n")
                .replacingOccurrences(of: "\r", with: "\\r")
                .replacingOccurrences(of: "\t", with: "\\t")
            result = result.replacingOccurrences(of: "{{content}}", with: escaped)
        } else {
            result = result.replacingOccurrences(of: "{{content}}", with: "")
        }

        return result
    }
}

// MARK: - Webhook Result

struct WebhookResult {
    let webhook: WebhookConfig
    let success: Bool
    let statusCode: Int?
    let error: String?
    let timestamp: Date

    init(webhook: WebhookConfig, success: Bool, statusCode: Int? = nil, error: String? = nil) {
        self.webhook = webhook
        self.success = success
        self.statusCode = statusCode
        self.error = error
        self.timestamp = Date()
    }
}
