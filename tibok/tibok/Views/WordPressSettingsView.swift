//
//  WordPressSettingsView.swift
//  tibok
//
//  Settings UI for WordPress publishing configuration
//  Integrates with Keychain for secure password storage
//

import SwiftUI

struct WordPressSettingsView: View {

    // MARK: - Integration Method

    enum IntegrationMethod: String, CaseIterable, Identifiable {
        case email = "email"
        case api = "api"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .email: return "Post by Email"
            case .api: return "REST API"
            }
        }

        var description: String {
            switch self {
            case .email: return "Send posts via email to your WordPress site"
            case .api: return "Publish directly using WordPress REST API v2"
            }
        }
    }

    @AppStorage("plugin.wordpress.integrationMethod") private var integrationMethod: String = IntegrationMethod.api.rawValue

    // MARK: - Email Settings

    @AppStorage("plugin.wordpress.emailAddress") private var emailAddress = ""

    // MARK: - API Settings (Non-sensitive)

    @AppStorage("plugin.wordpress.siteURL") private var siteURL = ""
    @AppStorage("plugin.wordpress.username") private var username = ""
    @AppStorage("plugin.wordpress.defaultStatus") private var defaultStatus = "draft"
    @AppStorage("plugin.wordpress.defaultCategories") private var defaultCategories = ""
    @AppStorage("plugin.wordpress.defaultAuthor") private var defaultAuthor = ""
    @AppStorage("plugin.wordpress.defaultDescription") private var defaultDescription = ""

    // MARK: - Password State (Keychain-backed)

    @State private var appPassword = ""
    @State private var showPassword = false

    // MARK: - Connection Test State

    @State private var isTestingConnection = false
    @State private var testResult: ConnectionTestResult?

    // Multi-blog discovery state
    @State private var isDiscoveringBlogs = false
    @State private var selectedBlogID: Int = 0

    // MARK: - Keychain Constants

    private let keychainService = "com.tibok.wordpress"
    private let keychainAccount = "application-password"

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Plugin status hint (shown when plugin is disabled)
                if !PluginManager.shared.isLoaded("com.tibok.wordpress-export") {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                            .font(.title3)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Plugin Not Enabled")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text("Enable the WordPress Export plugin in **Settings > Plugins** to use this feature.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }

                Form {
                    // Section 1: Integration Method Selection
                    GroupBox("Integration Method") {
                        VStack(alignment: .leading, spacing: 12) {
                            Picker("Method", selection: $integrationMethod) {
                                ForEach(IntegrationMethod.allCases) { method in
                                    Text(method.displayName).tag(method.rawValue)
                                }
                            }
                            .pickerStyle(.segmented)

                            // Description of selected method
                            if let selectedMethod = IntegrationMethod(rawValue: integrationMethod) {
                                Text(selectedMethod.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(8)
                    }

                    // Section 2: Method-specific Configuration (Progressive Disclosure)
                    if integrationMethod == IntegrationMethod.email.rawValue {
                        // EMAIL INTEGRATION
                        emailIntegrationView
                    } else {
                        // API INTEGRATION
                        apiIntegrationView
                    }

                    // Section 3: Default Settings (Shared)
                    defaultSettingsView

                    // Section 4: How to Use (Method-specific)
                    howToUseView
                }
                .formStyle(.grouped)
            }
        }
        .padding()
        .onAppear {
            // Load password from Keychain on view appear
            appPassword = KeychainHelper.load(
                service: keychainService,
                account: keychainAccount
            ) ?? ""
        }
        .onChange(of: appPassword) { _, newValue in
            // Save password to Keychain when changed
            if newValue.isEmpty {
                KeychainHelper.delete(service: keychainService, account: keychainAccount)
            } else {
                KeychainHelper.save(newValue, service: keychainService, account: keychainAccount)
            }
        }
    }

    // MARK: - Email Integration View

    private var emailIntegrationView: some View {
        GroupBox("Email Configuration") {
            VStack(alignment: .leading, spacing: 12) {
                TextField("Email Address", text: $emailAddress)
                    .textFieldStyle(.roundedBorder)
                Text("Enter your WordPress site's post-by-email address")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("How to get your email address:")
                        .font(.caption)
                        .fontWeight(.medium)
                    Text("1. Log into WordPress\n2. Go to Settings > Writing\n3. Look for \"Post via email\" section\n4. Copy the email address shown")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(8)
        }
    }

    // MARK: - API Integration View

    private var apiIntegrationView: some View {
        GroupBox("API Configuration") {
            VStack(alignment: .leading, spacing: 12) {
                // Site URL
                TextField("Site URL", text: $siteURL)
                    .textFieldStyle(.roundedBorder)
                Text("Example: https://example.com")
                    .font(.caption)
                    .foregroundColor(.secondary)

                // Username
                TextField("Username", text: $username)
                    .textFieldStyle(.roundedBorder)

                // App Password with show/hide toggle
                HStack {
                    if showPassword {
                        TextField("Application Password", text: $appPassword)
                            .textFieldStyle(.roundedBorder)
                    } else {
                        SecureField("Application Password", text: $appPassword)
                            .textFieldStyle(.roundedBorder)
                    }
                    Button {
                        showPassword.toggle()
                    } label: {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                    }
                    .buttonStyle(.plain)
                }

                // Test Connection Button
                HStack {
                    Button("Test Connection") {
                        testConnection()
                    }
                    .disabled(siteURL.isEmpty || username.isEmpty || appPassword.isEmpty)

                    if isTestingConnection {
                        ProgressView()
                            .scaleEffect(0.7)
                    }
                }

                // Test Result
                if let result = testResult {
                    HStack {
                        Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(result.success ? .green : .red)
                        Text(result.message)
                            .font(.subheadline)
                    }
                }

                // Help text
                Text("Generate Application Password at: Settings > Users > Your Profile > Application Passwords")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)

                // P2 limitation note
                Text("Note: P2 sites require email posting. API publishing works with standard WordPress.com blogs and self-hosted sites.")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding(.top, 4)

                // Multi-blog discovery (WordPress.com only)
                if WordPressExporter.shared.isWordPressDotCom {
                    Divider()
                        .padding(.vertical, 8)

                    HStack {
                        Button("Discover Blogs") {
                            discoverBlogs()
                        }
                        .disabled(isDiscoveringBlogs || siteURL.isEmpty || username.isEmpty || appPassword.isEmpty)

                        if isDiscoveringBlogs {
                            ProgressView()
                                .scaleEffect(0.7)
                        }
                    }

                    // Blog picker (after discovery)
                    if !WordPressExporter.shared.sites.isEmpty {
                        Picker("Blog", selection: $selectedBlogID) {
                            ForEach(WordPressExporter.shared.sites) { site in
                                Text(site.displayName)
                                    .tag(site.id)
                            }
                        }
                        .onChange(of: selectedBlogID) { _, newValue in
                            WordPressExporter.shared.switchBlog(to: newValue)
                        }
                        .onAppear {
                            selectedBlogID = WordPressExporter.shared.activeSiteID
                        }

                        Text("\(WordPressExporter.shared.sites.count) \(WordPressExporter.shared.sites.count == 1 ? "blog" : "blogs") available")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(8)
        }
    }

    // MARK: - Default Settings View (Shared)

    private var defaultSettingsView: some View {
        GroupBox("Default Settings") {
            VStack(alignment: .leading, spacing: 12) {
                // Status picker
                Picker("Default Status", selection: $defaultStatus) {
                    ForEach(WordPressPostStatus.allCases) { status in
                        Text(status.displayName).tag(status.rawValue)
                    }
                }

                // Categories
                TextField("Default Categories", text: $defaultCategories)
                    .textFieldStyle(.roundedBorder)
                Text("Comma-separated: Blog, Tech, Tutorial")
                    .font(.caption)
                    .foregroundColor(.secondary)

                // Author
                TextField("Default Author", text: $defaultAuthor)
                    .textFieldStyle(.roundedBorder)

                // Description (excerpt)
                TextField("Default Description", text: $defaultDescription)
                    .textFieldStyle(.roundedBorder)
                Text("Used as post excerpt if not set in frontmatter")
                    .font(.caption)
                    .foregroundColor(.secondary)

                // Override note with Frontmatter link
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                            .font(.caption)
                        Text("Override per-document in **Frontmatter Inspector (⌘I)**")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Text("Set **title**, **description**, **categories**, or **draft** status in frontmatter to override these defaults.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 18)
                }
                .padding(.top, 8)
            }
            .padding(8)
        }
    }

    // MARK: - How to Use View (Method-specific)

    private var howToUseView: some View {
        GroupBox("How to Use") {
            VStack(alignment: .leading, spacing: 8) {
                if integrationMethod == IntegrationMethod.email.rawValue {
                    // Email integration instructions
                    HStack(alignment: .top) {
                        Text("①")
                        Text("Configure email address above")
                    }
                    HStack(alignment: .top) {
                        Text("②")
                        Text("Use Command Palette (⌘K) and search \"WordPress\"")
                    }
                    HStack(alignment: .top) {
                        Text("③")
                        Text("Your post will be emailed to WordPress")
                    }
                    HStack(alignment: .top) {
                        Text("④")
                        Text("Override defaults with frontmatter fields:")
                    }
                    Text("""
                    ---
                    title: My Post Title
                    description: Post excerpt/summary
                    categories: [Blog, Tutorial]
                    tags: [markdown, writing]
                    draft: true
                    author: John Doe
                    ---
                    """)
                    .font(.system(.caption, design: .monospaced))
                    .padding(8)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(4)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Field Notes:")
                            .font(.caption)
                            .fontWeight(.semibold)
                        Text("• author: Display name string. Behavior depends on your WordPress email settings.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("• layout: Jekyll/Hugo only. Ignored by WordPress (uses themes/templates).")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 4)
                } else {
                    // API integration instructions
                    HStack(alignment: .top) {
                        Text("①")
                        Text("Configure site URL and credentials above")
                    }
                    HStack(alignment: .top) {
                        Text("②")
                        Text("Use Command Palette (⌘K) and search \"WordPress\"")
                    }
                    HStack(alignment: .top) {
                        Text("③")
                        Text("Override defaults with frontmatter fields:")
                    }
                    Text("""
                    ---
                    title: My Post Title
                    description: Post excerpt/summary
                    categories: [Blog, Tutorial]
                    tags: [markdown, writing]
                    draft: true
                    author: John Doe
                    ---
                    """)
                    .font(.system(.caption, design: .monospaced))
                    .padding(8)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(4)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Field Notes:")
                            .font(.caption)
                            .fontWeight(.semibold)
                        Text("• author: Display name string. If not found, uses authenticated user.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("• layout: Jekyll/Hugo only. Ignored by WordPress (uses themes/templates).")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 4)
                }
            }
            .padding(8)
            .font(.subheadline)
        }
    }

    // MARK: - Methods

    private func testConnection() {
        isTestingConnection = true
        Task {
            testResult = await WordPressExporter.shared.testConnection()
            isTestingConnection = false

            // Show success toast
            if let result = testResult, result.success {
                UIStateService.shared.showToast(
                    "Connected to \(result.siteName ?? siteURL)",
                    icon: "checkmark.circle.fill"
                )
            }
        }
    }

    private func discoverBlogs() {
        isDiscoveringBlogs = true
        Task {
            let result = await WordPressExporter.shared.discoverBlogs()
            isDiscoveringBlogs = false

            switch result {
            case .success(let count):
                UIStateService.shared.showToast(
                    "Discovered \(count) \(count == 1 ? "blog" : "blogs")",
                    icon: "checkmark.circle.fill"
                )
            case .notWordPressCom:
                UIStateService.shared.showToast(
                    "Blog discovery only works with WordPress.com",
                    icon: "info.circle"
                )
            case .authenticationFailed:
                UIStateService.shared.showToast(
                    "Authentication failed. Check credentials.",
                    icon: "xmark.circle.fill"
                )
            case .networkError(let message):
                UIStateService.shared.showToast(
                    "Network error: \(message)",
                    icon: "exclamationmark.triangle"
                )
            }
        }
    }
}
