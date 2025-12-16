//
//  WebhookSettingsView.swift
//  tibok
//
//  Settings view for managing webhooks.
//

import SwiftUI

struct WebhookSettingsView: View {
    @ObservedObject var webhookService = WebhookService.shared
    @State private var showAddSheet = false
    @State private var editingWebhook: WebhookConfig?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            Text("Webhooks")
                .font(.headline)

            Text("Webhooks are HTTP requests triggered when events occur, such as saving a document or pushing to Git.")
                .font(.caption)
                .foregroundColor(.secondary)

            Divider()

            // Webhook list
            if webhookService.webhooks.isEmpty {
                VStack(spacing: 8) {
                    Text("No webhooks configured")
                        .foregroundColor(.secondary)
                    Button("Add Webhook") {
                        showAddSheet = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(webhookService.webhooks) { webhook in
                        WebhookRow(webhook: webhook) {
                            editingWebhook = webhook
                        } onToggle: {
                            webhookService.toggleWebhook(webhook)
                        } onDelete: {
                            webhookService.deleteWebhook(webhook)
                        }
                    }
                }
                .listStyle(.inset)

                HStack {
                    Button {
                        showAddSheet = true
                    } label: {
                        Label("Add Webhook", systemImage: "plus")
                    }

                    Spacer()
                }
            }
        }
        .padding()
        .sheet(isPresented: $showAddSheet) {
            WebhookEditorSheet(webhook: .new()) { newWebhook in
                webhookService.addWebhook(newWebhook)
            }
        }
        .sheet(item: $editingWebhook) { webhook in
            WebhookEditorSheet(webhook: webhook) { updatedWebhook in
                webhookService.updateWebhook(updatedWebhook)
            }
        }
    }
}

// MARK: - Webhook Row

struct WebhookRow: View {
    let webhook: WebhookConfig
    let onEdit: () -> Void
    let onToggle: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(webhook.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(webhook.isEnabled ? .primary : .secondary)

                Text(webhook.url)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text(webhook.method.rawValue)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.accentColor.opacity(0.15))
                        .cornerRadius(3)

                    ForEach(Array(webhook.events), id: \.self) { event in
                        Text(event.displayName)
                            .font(.system(size: 10))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.secondary.opacity(0.15))
                            .cornerRadius(3)
                    }
                }
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { webhook.isEnabled },
                set: { _ in onToggle() }
            ))
            .labelsHidden()

            Button {
                onEdit()
            } label: {
                Image(systemName: "pencil")
            }
            .buttonStyle(.plain)

            Button {
                onDelete()
            } label: {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Webhook Editor Sheet

struct WebhookEditorSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var webhook: WebhookConfig
    @State private var testResult: WebhookResult?
    @State private var isTesting = false

    let onSave: (WebhookConfig) -> Void

    init(webhook: WebhookConfig, onSave: @escaping (WebhookConfig) -> Void) {
        _webhook = State(initialValue: webhook)
        self.onSave = onSave
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Text(webhook.name.isEmpty ? "New Webhook" : webhook.name)
                    .font(.headline)

                Spacer()

                Button("Save") {
                    onSave(webhook)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(webhook.name.isEmpty || webhook.url.isEmpty)
            }
            .padding()

            Divider()

            // Form
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Basic info
                    GroupBox("Basic") {
                        VStack(alignment: .leading, spacing: 12) {
                            LabeledContent("Name") {
                                TextField("Webhook name", text: $webhook.name)
                                    .textFieldStyle(.roundedBorder)
                            }

                            LabeledContent("URL") {
                                TextField("https://example.com/webhook", text: $webhook.url)
                                    .textFieldStyle(.roundedBorder)
                            }

                            LabeledContent("Method") {
                                Picker("", selection: $webhook.method) {
                                    ForEach(HTTPMethod.allCases, id: \.self) { method in
                                        Text(method.rawValue).tag(method)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 200)
                            }
                        }
                        .padding(.vertical, 8)
                    }

                    // Events
                    GroupBox("Events") {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(WebhookEvent.allCases) { event in
                                HStack {
                                    Toggle(isOn: Binding(
                                        get: { webhook.events.contains(event) },
                                        set: { isSelected in
                                            if isSelected {
                                                webhook.events.insert(event)
                                            } else {
                                                webhook.events.remove(event)
                                            }
                                        }
                                    )) {
                                        VStack(alignment: .leading, spacing: 1) {
                                            Text(event.displayName)
                                                .font(.system(size: 13))
                                            Text(event.description)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }

                    // Headers
                    GroupBox("Headers") {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(Array(webhook.headers.keys.sorted()), id: \.self) { key in
                                HStack {
                                    Text(key)
                                        .font(.system(size: 12, design: .monospaced))
                                        .frame(width: 120, alignment: .leading)
                                    Text(webhook.headers[key] ?? "")
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Button {
                                        webhook.headers.removeValue(forKey: key)
                                    } label: {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundColor(.red)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }

                            HeaderEditor { key, value in
                                webhook.headers[key] = value
                            }
                        }
                        .padding(.vertical, 8)
                    }

                    // Payload
                    GroupBox("Payload Template") {
                        VStack(alignment: .leading, spacing: 8) {
                            TextEditor(text: Binding(
                                get: { webhook.payloadTemplate ?? "" },
                                set: { webhook.payloadTemplate = $0.isEmpty ? nil : $0 }
                            ))
                            .font(.system(size: 12, design: .monospaced))
                            .frame(height: 120)
                            .border(Color.secondary.opacity(0.3))

                            Text("Variables: {{event}}, {{filename}}, {{title}}, {{path}}, {{timestamp}}, {{content}}")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    }

                    // Test
                    GroupBox("Test") {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Button {
                                    Task {
                                        isTesting = true
                                        testResult = await WebhookService.shared.testWebhook(webhook)
                                        isTesting = false
                                    }
                                } label: {
                                    if isTesting {
                                        ProgressView()
                                            .controlSize(.small)
                                    } else {
                                        Text("Send Test Request")
                                    }
                                }
                                .disabled(webhook.url.isEmpty || isTesting)

                                Spacer()

                                if let result = testResult {
                                    HStack(spacing: 4) {
                                        Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                                            .foregroundColor(result.success ? .green : .red)
                                        if let statusCode = result.statusCode {
                                            Text("HTTP \(statusCode)")
                                                .font(.caption)
                                        }
                                        if let error = result.error, !result.success {
                                            Text(error)
                                                .font(.caption)
                                                .foregroundColor(.red)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                .padding()
            }
        }
        .frame(width: 500, height: 600)
    }
}

// MARK: - Header Editor

struct HeaderEditor: View {
    @State private var key = ""
    @State private var value = ""

    let onAdd: (String, String) -> Void

    var body: some View {
        HStack {
            TextField("Header", text: $key)
                .textFieldStyle(.roundedBorder)
                .frame(width: 120)

            TextField("Value", text: $value)
                .textFieldStyle(.roundedBorder)

            Button {
                if !key.isEmpty && !value.isEmpty {
                    onAdd(key, value)
                    key = ""
                    value = ""
                }
            } label: {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.green)
            }
            .buttonStyle(.plain)
            .disabled(key.isEmpty || value.isEmpty)
        }
    }
}

// MARK: - Labeled Content Helper

struct LabeledContent<Content: View>: View {
    let label: String
    let content: Content

    init(_ label: String, @ViewBuilder content: () -> Content) {
        self.label = label
        self.content = content()
    }

    var body: some View {
        HStack(alignment: .center) {
            Text(label)
                .frame(width: 60, alignment: .trailing)
                .foregroundColor(.secondary)
            content
        }
    }
}
