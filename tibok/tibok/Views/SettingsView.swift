//
//  SettingsView.swift
//  tibok
//
//  App settings/preferences window.
//

import SwiftUI

enum L10n {
    enum Tabs {
        static let general = "General"
        static let editor = "Editor"
        static let preview = "Preview"
        static let about = "About"
    }
    enum General {
        static let appearanceSection = "Appearance"
        static let themePicker = "Theme"
        static let themeHelp = "Choose how tibok appears on your Mac"
        static let savingSection = "Saving"
        static let autoSaveToggle = "Auto-save documents"
        static let autoSaveHelp = "Automatically save changes as you type"
        static let helpSection = "Help & Support"
        static let reportIssue = "Report an Issue..."
        static let reportIssueHelp = "Open GitHub to report a bug or request a feature"
    }
    enum Appearance {
        static let system = "System"
        static let light = "Light"
        static let dark = "Dark"
    }
    enum Editor {
        static let fontSection = "Font"
        static let fontSize = "Font Size"
        static let fontSizeHelp = "Size of the editor font in points"
        static let fontFamily = "Font"
        static let fontFamilyHelp = "Choose the editor font"
        static let layoutSection = "Layout"
        static let lineHeight = "Line Height"
        static let lineHeightHelp = "Spacing between lines (1.0 = single, 1.5 = one and a half)"
        static let highlightingSection = "Highlighting"
        static let syntaxHighlighting = "Syntax Highlighting"
        static let syntaxHighlightingHelp = "Colorize markdown syntax in the editor"
        static let spellCheck = "Spell Check"
        static let spellCheckHelp = "Check spelling while typing"
        static let focusSection = "Focus"
        static let focusMode = "Focus Mode"
        static let focusModeHelp = "Dim text outside the current paragraph"
        static let inputSection = "Input"
        static let autoPairs = "Auto-close Brackets"
        static let autoPairsHelp = "Automatically insert closing brackets, quotes, and markdown delimiters"
        static let smartLists = "Smart Lists"
        static let smartListsHelp = "Auto-continue bullet and numbered lists when pressing Enter"
    }
    enum Preview {
        static let fontSection = "Font"
        static let fontSize = "Font Size"
        static let fontSizeHelp = "Base font size for preview content"
        static let layoutSection = "Layout"
        static let maxWidth = "Content Width"
        static let maxWidthHelp = "Maximum width of preview content"
        static let codeSection = "Code"
        static let codeTheme = "Code Theme"
        static let codeThemeHelp = "Syntax highlighting theme for code blocks"
    }
    enum About {
        static let section = "About tibok"
        static let versionFormat = "Version %@ (%@)"
        static let copyVersion = "Copy Version Info"
        static let showInFinder = "Show in Finder"
        static let website = "Website"

        static let copyVersionHelp = "Copy app version to clipboard"
        static let showInFinderHelp = "Reveal the app bundle in Finder"
        static let websiteHelp = "Visit the tibok website"
    }
}

enum AppURLs {
    static let issues = URL(string: "https://github.com/anthropics/tibok/issues")!
    static let website = URL(string: "https://github.com/anthropics/tibok")
}

enum SettingsKeys {
    static let autoSaveEnabled = "autoSaveEnabled"
    static let appearanceMode = "appearanceMode"
    // Editor settings
    static let editorFontSize = "editor.fontSize"
    static let editorFontFamily = "editor.fontFamily"
    static let editorLineHeight = "editor.lineHeight"
    static let editorSyntaxHighlighting = "editor.syntaxHighlighting"
    static let editorSpellCheck = "editor.spellCheck"
    static let editorFocusMode = "editor.focusMode"
    static let editorAutoPairs = "editor.autoPairs"
    static let editorSmartLists = "editor.smartLists"
    // Preview settings
    static let previewFontSize = "preview.fontSize"
    static let previewMaxWidth = "preview.maxWidth"
    static let previewCodeTheme = "preview.codeTheme"
}

enum AppearanceMode: String, CaseIterable {
    case system = "system"
    case light = "light"
    case dark = "dark"

    var displayName: String {
        switch self {
        case .system: return L10n.Appearance.system
        case .light: return L10n.Appearance.light
        case .dark: return L10n.Appearance.dark
        }
    }

    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max"
        case .dark: return "moon"
        }
    }
}

struct SettingsView: View {
    @AppStorage(SettingsKeys.autoSaveEnabled) private var autoSaveEnabled = true
    @AppStorage(SettingsKeys.appearanceMode) private var appearanceMode: String = AppearanceMode.system.rawValue

    var body: some View {
        TabView {
            GeneralSettingsView(autoSaveEnabled: $autoSaveEnabled, appearanceMode: $appearanceMode)
                .tabItem {
                    Label(L10n.Tabs.general, systemImage: "gear")
                }

            EditorSettingsView()
                .tabItem {
                    Label(L10n.Tabs.editor, systemImage: "pencil")
                }

            PreviewSettingsView()
                .tabItem {
                    Label(L10n.Tabs.preview, systemImage: "eye")
                }

            AboutSettingsView()
                .tabItem {
                    Label(L10n.Tabs.about, systemImage: "info.circle")
                }
        }
        .frame(width: 450, height: 380)
    }
}

struct GeneralSettingsView: View {
    @Binding var autoSaveEnabled: Bool
    @Binding var appearanceMode: String

    var body: some View {
        Form {
            Section(L10n.General.appearanceSection) {
                Picker(L10n.General.themePicker, selection: $appearanceMode) {
                    ForEach(AppearanceMode.allCases, id: \.rawValue) { mode in
                        Label(mode.displayName, systemImage: mode.icon)
                            .tag(mode.rawValue)
                    }
                }
                .pickerStyle(.radioGroup)
                .help(L10n.General.themeHelp)
                .onChange(of: appearanceMode) { _, newValue in
                    applyAppearance(AppearanceMode(rawValue: newValue) ?? .system)
                }
            }

            Section(L10n.General.savingSection) {
                Toggle(L10n.General.autoSaveToggle, isOn: $autoSaveEnabled)
                    .help(L10n.General.autoSaveHelp)
            }

            Section(L10n.General.helpSection) {
                Button {
                    openIssuesPage()
                } label: {
                    Label(L10n.General.reportIssue, systemImage: "lifepreserver")
                }
                .help(L10n.General.reportIssueHelp)
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear {
            applyAppearance(AppearanceMode(rawValue: appearanceMode) ?? .system)
        }
    }

    private func applyAppearance(_ mode: AppearanceMode) {
        switch mode {
        case .system:
            NSApp.appearance = nil
        case .light:
            NSApp.appearance = NSAppearance(named: .aqua)
        case .dark:
            NSApp.appearance = NSAppearance(named: .darkAqua)
        }
    }

    private func openIssuesPage() {
        let url = AppURLs.issues
        guard url.scheme == "https", url.host == "github.com" else { return }
        let config = NSWorkspace.OpenConfiguration()
        NSWorkspace.shared.open(url, configuration: config) { _, _ in }
    }
}

// Available monospace fonts for the editor
enum EditorFont: String, CaseIterable {
    case system = "System Mono"
    case menlo = "Menlo"
    case monaco = "Monaco"
    case sfMono = "SF Mono"
    case jetbrainsMono = "JetBrains Mono"
    case firaCode = "Fira Code"
    case sourceCodePro = "Source Code Pro"

    var fontName: String {
        switch self {
        case .system: return ".AppleSystemUIFontMonospaced"
        case .menlo: return "Menlo"
        case .monaco: return "Monaco"
        case .sfMono: return "SFMono-Regular"
        case .jetbrainsMono: return "JetBrainsMono-Regular"
        case .firaCode: return "FiraCode-Regular"
        case .sourceCodePro: return "SourceCodePro-Regular"
        }
    }

    var displayName: String { rawValue }

    var isAvailable: Bool {
        if self == .system { return true }
        return NSFont(name: fontName, size: 12) != nil
    }

    static var availableFonts: [EditorFont] {
        allCases.filter { $0.isAvailable }
    }
}

// Code highlighting themes
enum CodeTheme: String, CaseIterable {
    case atom = "atom-one-dark"
    case github = "github"
    case monokai = "monokai"
    case vs = "vs"
    case xcode = "xcode"
    case dracula = "dracula"

    var displayName: String {
        switch self {
        case .atom: return "Atom One Dark"
        case .github: return "GitHub"
        case .monokai: return "Monokai"
        case .vs: return "VS Code"
        case .xcode: return "Xcode"
        case .dracula: return "Dracula"
        }
    }
}

// Preview content width options
enum PreviewWidth: Int, CaseIterable {
    case narrow = 600
    case medium = 720
    case wide = 900
    case full = 0

    var displayName: String {
        switch self {
        case .narrow: return "Narrow (600px)"
        case .medium: return "Medium (720px)"
        case .wide: return "Wide (900px)"
        case .full: return "Full Width"
        }
    }
}

struct EditorSettingsView: View {
    @AppStorage(SettingsKeys.editorFontSize) private var fontSize: Double = 14
    @AppStorage(SettingsKeys.editorFontFamily) private var fontFamily: String = EditorFont.system.rawValue
    @AppStorage(SettingsKeys.editorLineHeight) private var lineHeight: Double = 1.4
    @AppStorage(SettingsKeys.editorSyntaxHighlighting) private var syntaxHighlighting: Bool = true
    @AppStorage(SettingsKeys.editorSpellCheck) private var spellCheck: Bool = false
    @AppStorage(SettingsKeys.editorFocusMode) private var focusMode: Bool = false
    @AppStorage(SettingsKeys.editorAutoPairs) private var autoPairs: Bool = true
    @AppStorage(SettingsKeys.editorSmartLists) private var smartLists: Bool = true

    var body: some View {
        Form {
            Section(L10n.Editor.fontSection) {
                Picker(L10n.Editor.fontFamily, selection: $fontFamily) {
                    ForEach(EditorFont.availableFonts, id: \.rawValue) { font in
                        Text(font.displayName).tag(font.rawValue)
                    }
                }
                .help(L10n.Editor.fontFamilyHelp)

                HStack {
                    Text(L10n.Editor.fontSize)
                    Spacer()
                    Stepper(value: $fontSize, in: 10...24, step: 1) {
                        Text("\(Int(fontSize)) pt")
                            .frame(width: 50, alignment: .trailing)
                    }
                }
                .help(L10n.Editor.fontSizeHelp)
            }

            Section(L10n.Editor.layoutSection) {
                HStack {
                    Text(L10n.Editor.lineHeight)
                    Spacer()
                    Picker("", selection: $lineHeight) {
                        Text("Compact (1.2)").tag(1.2)
                        Text("Normal (1.4)").tag(1.4)
                        Text("Relaxed (1.6)").tag(1.6)
                        Text("Spacious (1.8)").tag(1.8)
                    }
                    .labelsHidden()
                    .frame(width: 150)
                }
                .help(L10n.Editor.lineHeightHelp)
            }

            Section(L10n.Editor.highlightingSection) {
                Toggle(L10n.Editor.syntaxHighlighting, isOn: $syntaxHighlighting)
                    .help(L10n.Editor.syntaxHighlightingHelp)

                Toggle(L10n.Editor.spellCheck, isOn: $spellCheck)
                    .help(L10n.Editor.spellCheckHelp)
            }

            Section(L10n.Editor.focusSection) {
                Toggle(L10n.Editor.focusMode, isOn: $focusMode)
                    .help(L10n.Editor.focusModeHelp)
            }

            Section(L10n.Editor.inputSection) {
                Toggle(L10n.Editor.autoPairs, isOn: $autoPairs)
                    .help(L10n.Editor.autoPairsHelp)

                Toggle(L10n.Editor.smartLists, isOn: $smartLists)
                    .help(L10n.Editor.smartListsHelp)
            }

            // Preview section
            Section("Preview") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sample text with current settings:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("The quick brown fox jumps over the lazy dog.")
                        .font(.custom(
                            EditorFont(rawValue: fontFamily)?.fontName ?? ".AppleSystemUIFontMonospaced",
                            size: fontSize
                        ))
                        .lineSpacing((lineHeight - 1.0) * fontSize)
                        .padding(8)
                        .background(Color(NSColor.textBackgroundColor))
                        .cornerRadius(4)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

struct PreviewSettingsView: View {
    @AppStorage(SettingsKeys.previewFontSize) private var fontSize: Double = 16
    @AppStorage(SettingsKeys.previewMaxWidth) private var maxWidth: Int = PreviewWidth.medium.rawValue
    @AppStorage(SettingsKeys.previewCodeTheme) private var codeTheme: String = CodeTheme.atom.rawValue

    var body: some View {
        Form {
            Section(L10n.Preview.fontSection) {
                HStack {
                    Text(L10n.Preview.fontSize)
                    Spacer()
                    Stepper(value: $fontSize, in: 12...24, step: 1) {
                        Text("\(Int(fontSize)) pt")
                            .frame(width: 50, alignment: .trailing)
                    }
                }
                .help(L10n.Preview.fontSizeHelp)
            }

            Section(L10n.Preview.layoutSection) {
                Picker(L10n.Preview.maxWidth, selection: $maxWidth) {
                    ForEach(PreviewWidth.allCases, id: \.rawValue) { width in
                        Text(width.displayName).tag(width.rawValue)
                    }
                }
                .help(L10n.Preview.maxWidthHelp)
            }

            Section(L10n.Preview.codeSection) {
                Picker(L10n.Preview.codeTheme, selection: $codeTheme) {
                    ForEach(CodeTheme.allCases, id: \.rawValue) { theme in
                        Text(theme.displayName).tag(theme.rawValue)
                    }
                }
                .help(L10n.Preview.codeThemeHelp)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

struct AboutSettingsView: View {
    private var appName: String { Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "App" }
    private var version: String { Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "" }
    private var build: String { Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "" }

    private func copyVersionInfoToClipboard() {
        let info = "\(appName) \(version) (\(build))"
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(info, forType: .string)
    }

    private func revealAppInFinder() {
        let appURL = Bundle.main.bundleURL
        NSWorkspace.shared.activateFileViewerSelecting([appURL])
    }

    var body: some View {
        Form {
            Section(L10n.About.section) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(appName)
                        .font(.title3)
                        .bold()
                    Text(String(format: L10n.About.versionFormat, version, build))
                        .foregroundColor(.secondary)
                }
                VStack(alignment: .leading, spacing: 8) {
                    Button {
                        copyVersionInfoToClipboard()
                    } label: {
                        Label(L10n.About.copyVersion, systemImage: "doc.on.doc")
                    }
                    .help(L10n.About.copyVersionHelp)

                    Button {
                        revealAppInFinder()
                    } label: {
                        Label(L10n.About.showInFinder, systemImage: "folder")
                    }
                    .help(L10n.About.showInFinderHelp)

                    if let website = AppURLs.website, website.scheme == "https" {
                        Button {
                            NSWorkspace.shared.open(website)
                        } label: {
                            Label(L10n.About.website, systemImage: "safari")
                        }
                        .help(L10n.About.websiteHelp)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// Preview available in Xcode
// #Preview {
//     SettingsView()
// }

