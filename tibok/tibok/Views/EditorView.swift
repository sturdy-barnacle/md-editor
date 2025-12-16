//
//  EditorView.swift
//  tibok
//
//  Markdown editor view with find/replace and slash commands support.
//

import SwiftUI
import AppKit

struct EditorView: View {
    @EnvironmentObject var appState: AppState
    @State private var slashCommandState = SlashCommandState()
    @State private var emojiState = EmojiState()

    /// Binding to the active document's content
    private var contentBinding: Binding<String> {
        Binding(
            get: { appState.activeDocument?.content ?? "" },
            set: { newValue in
                if let index = appState.activeDocumentIndex {
                    appState.documents[index].content = newValue
                }
            }
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            if appState.hasNoDocuments {
                // Empty state
                EditorEmptyStateView()
            } else if let doc = appState.activeDocument {
                // Editor with NSTextView for find/replace support
                FindableTextEditor(
                    text: contentBinding,
                    slashState: $slashCommandState,
                    emojiState: $emojiState,
                    documentURL: { appState.activeDocument?.fileURL }
                )
                .id(doc.id) // Force recreate when document changes
                .onChange(of: doc.content) { _, _ in
                    appState.documentDidChange()
                }
            }
        }
        .background(Color(NSColor.textBackgroundColor))
    }
}

// MARK: - Editor Empty State

struct EditorEmptyStateView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))

            Text("No Document Open")
                .font(.title2)
                .foregroundColor(.secondary)

            VStack(spacing: 12) {
                Button {
                    appState.createNewDocument()
                } label: {
                    Label("Create New Document", systemImage: "doc.badge.plus")
                        .frame(width: 200)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Button {
                    appState.openDocument()
                } label: {
                    Label("Open File...", systemImage: "doc")
                        .frame(width: 200)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Button {
                    appState.openWorkspace()
                } label: {
                    Label("Open Folder...", systemImage: "folder")
                        .frame(width: 200)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }

            // Keyboard shortcut hints
            Text("⌘N new  •  ⌘O open  •  ⌘K commands")
                .font(.system(size: 11))
                .foregroundColor(.secondary.opacity(0.6))
                .padding(.top, 8)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Slash Command State

class SlashCommandState: ObservableObject {
    @Published var isActive = false
    @Published var query = ""
    @Published var position: NSPoint = .zero
    var slashRange: NSRange?
    weak var textView: NSTextView?
}

// MARK: - Emoji State

class EmojiState: ObservableObject {
    @Published var isActive = false
    @Published var query = ""
    var colonRange: NSRange?
}

// MARK: - Slash Commands
// SlashCommand struct and registry now in Plugins/SlashCommandRegistry.swift

// MARK: - Emoji Items

struct EmojiItem: Identifiable {
    let id: String  // shortcode
    let emoji: String
    let keywords: [String]

    static let all: [EmojiItem] = [
        // Smileys & Emotion
        EmojiItem(id: "smile", emoji: "😄", keywords: ["happy", "face", "grin"]),
        EmojiItem(id: "grin", emoji: "😁", keywords: ["happy", "face", "smile"]),
        EmojiItem(id: "joy", emoji: "😂", keywords: ["laugh", "cry", "tears", "lol"]),
        EmojiItem(id: "rofl", emoji: "🤣", keywords: ["laugh", "floor", "funny"]),
        EmojiItem(id: "smiley", emoji: "😃", keywords: ["happy", "face"]),
        EmojiItem(id: "laugh", emoji: "😆", keywords: ["happy", "haha", "xd"]),
        EmojiItem(id: "wink", emoji: "😉", keywords: ["face", "flirt"]),
        EmojiItem(id: "blush", emoji: "😊", keywords: ["happy", "shy", "smile"]),
        EmojiItem(id: "heart_eyes", emoji: "😍", keywords: ["love", "crush", "adore"]),
        EmojiItem(id: "kissing_heart", emoji: "😘", keywords: ["love", "kiss", "flirt"]),
        EmojiItem(id: "thinking", emoji: "🤔", keywords: ["hmm", "consider", "ponder"]),
        EmojiItem(id: "neutral", emoji: "😐", keywords: ["meh", "face", "blank"]),
        EmojiItem(id: "unamused", emoji: "😒", keywords: ["meh", "annoyed", "bored"]),
        EmojiItem(id: "sweat", emoji: "😓", keywords: ["nervous", "anxious"]),
        EmojiItem(id: "cry", emoji: "😢", keywords: ["sad", "tear", "upset"]),
        EmojiItem(id: "sob", emoji: "😭", keywords: ["cry", "sad", "tears"]),
        EmojiItem(id: "scream", emoji: "😱", keywords: ["scared", "shocked", "horror"]),
        EmojiItem(id: "angry", emoji: "😠", keywords: ["mad", "annoyed"]),
        EmojiItem(id: "rage", emoji: "😡", keywords: ["angry", "mad", "furious"]),
        EmojiItem(id: "sunglasses", emoji: "😎", keywords: ["cool", "face", "awesome"]),
        EmojiItem(id: "nerd", emoji: "🤓", keywords: ["glasses", "geek", "smart"]),
        EmojiItem(id: "sleeping", emoji: "😴", keywords: ["tired", "zzz", "sleep"]),
        EmojiItem(id: "yum", emoji: "😋", keywords: ["delicious", "tasty", "tongue"]),
        EmojiItem(id: "skull", emoji: "💀", keywords: ["dead", "death", "skeleton"]),
        EmojiItem(id: "ghost", emoji: "👻", keywords: ["spooky", "halloween", "boo"]),
        EmojiItem(id: "alien", emoji: "👽", keywords: ["space", "ufo", "extraterrestrial"]),
        EmojiItem(id: "robot", emoji: "🤖", keywords: ["machine", "ai", "bot"]),
        EmojiItem(id: "poop", emoji: "💩", keywords: ["shit", "crap", "poo"]),
        EmojiItem(id: "clown", emoji: "🤡", keywords: ["face", "circus", "funny"]),

        // Hearts & Symbols
        EmojiItem(id: "heart", emoji: "❤️", keywords: ["love", "red"]),
        EmojiItem(id: "broken_heart", emoji: "💔", keywords: ["sad", "breakup"]),
        EmojiItem(id: "fire", emoji: "🔥", keywords: ["hot", "flame", "lit"]),
        EmojiItem(id: "sparkles", emoji: "✨", keywords: ["shine", "magic", "star"]),
        EmojiItem(id: "star", emoji: "⭐", keywords: ["favorite", "rating"]),
        EmojiItem(id: "zap", emoji: "⚡", keywords: ["lightning", "electric", "bolt"]),
        EmojiItem(id: "boom", emoji: "💥", keywords: ["explosion", "bang"]),
        EmojiItem(id: "100", emoji: "💯", keywords: ["perfect", "score", "hundred"]),

        // Gestures
        EmojiItem(id: "wave", emoji: "👋", keywords: ["hello", "goodbye", "hi"]),
        EmojiItem(id: "thumbsup", emoji: "👍", keywords: ["yes", "ok", "good", "+1"]),
        EmojiItem(id: "thumbsdown", emoji: "👎", keywords: ["no", "bad", "-1"]),
        EmojiItem(id: "clap", emoji: "👏", keywords: ["applause", "bravo"]),
        EmojiItem(id: "pray", emoji: "🙏", keywords: ["please", "thanks", "hope"]),
        EmojiItem(id: "muscle", emoji: "💪", keywords: ["strong", "flex", "arm"]),
        EmojiItem(id: "ok_hand", emoji: "👌", keywords: ["perfect", "fine"]),
        EmojiItem(id: "v", emoji: "✌️", keywords: ["peace", "victory", "two"]),
        EmojiItem(id: "point_right", emoji: "👉", keywords: ["finger", "direction"]),
        EmojiItem(id: "point_left", emoji: "👈", keywords: ["finger", "direction"]),
        EmojiItem(id: "point_up", emoji: "☝️", keywords: ["finger", "one"]),
        EmojiItem(id: "point_down", emoji: "👇", keywords: ["finger", "down"]),
        EmojiItem(id: "eyes", emoji: "👀", keywords: ["look", "see", "watch"]),
        EmojiItem(id: "brain", emoji: "🧠", keywords: ["smart", "think", "mind"]),

        // Animals
        EmojiItem(id: "dog", emoji: "🐕", keywords: ["pet", "puppy", "animal"]),
        EmojiItem(id: "cat", emoji: "🐱", keywords: ["pet", "kitty", "animal"]),
        EmojiItem(id: "fox", emoji: "🦊", keywords: ["animal", "clever"]),
        EmojiItem(id: "bear", emoji: "🐻", keywords: ["animal", "teddy"]),
        EmojiItem(id: "panda", emoji: "🐼", keywords: ["animal", "cute"]),
        EmojiItem(id: "unicorn", emoji: "🦄", keywords: ["magic", "horse", "fantasy"]),
        EmojiItem(id: "bee", emoji: "🐝", keywords: ["insect", "honey", "buzz"]),
        EmojiItem(id: "butterfly", emoji: "🦋", keywords: ["insect", "pretty"]),
        EmojiItem(id: "turtle", emoji: "🐢", keywords: ["slow", "animal", "shell"]),
        EmojiItem(id: "snake", emoji: "🐍", keywords: ["reptile", "slither"]),
        EmojiItem(id: "dragon", emoji: "🐉", keywords: ["fantasy", "fire"]),
        EmojiItem(id: "whale", emoji: "🐳", keywords: ["ocean", "sea", "big"]),
        EmojiItem(id: "dolphin", emoji: "🐬", keywords: ["ocean", "sea", "smart"]),
        EmojiItem(id: "shark", emoji: "🦈", keywords: ["ocean", "scary", "teeth"]),
        EmojiItem(id: "bird", emoji: "🐦", keywords: ["fly", "tweet", "animal"]),
        EmojiItem(id: "penguin", emoji: "🐧", keywords: ["cold", "cute", "animal"]),
        EmojiItem(id: "owl", emoji: "🦉", keywords: ["wise", "night", "bird"]),

        // Food & Drink
        EmojiItem(id: "apple", emoji: "🍎", keywords: ["fruit", "red", "food"]),
        EmojiItem(id: "pizza", emoji: "🍕", keywords: ["food", "italian", "slice"]),
        EmojiItem(id: "hamburger", emoji: "🍔", keywords: ["food", "burger", "fast"]),
        EmojiItem(id: "fries", emoji: "🍟", keywords: ["food", "chips", "fast"]),
        EmojiItem(id: "taco", emoji: "🌮", keywords: ["food", "mexican"]),
        EmojiItem(id: "sushi", emoji: "🍣", keywords: ["food", "japanese", "fish"]),
        EmojiItem(id: "ramen", emoji: "🍜", keywords: ["food", "noodles", "soup"]),
        EmojiItem(id: "coffee", emoji: "☕", keywords: ["drink", "caffeine", "morning"]),
        EmojiItem(id: "tea", emoji: "🍵", keywords: ["drink", "hot", "cup"]),
        EmojiItem(id: "beer", emoji: "🍺", keywords: ["drink", "alcohol", "bar"]),
        EmojiItem(id: "wine", emoji: "🍷", keywords: ["drink", "alcohol", "glass"]),
        EmojiItem(id: "cake", emoji: "🍰", keywords: ["food", "dessert", "birthday"]),
        EmojiItem(id: "cookie", emoji: "🍪", keywords: ["food", "snack", "sweet"]),
        EmojiItem(id: "ice_cream", emoji: "🍨", keywords: ["food", "dessert", "cold"]),
        EmojiItem(id: "donut", emoji: "🍩", keywords: ["food", "dessert", "sweet"]),

        // Objects & Tech
        EmojiItem(id: "computer", emoji: "💻", keywords: ["laptop", "tech", "work"]),
        EmojiItem(id: "phone", emoji: "📱", keywords: ["mobile", "cell", "device"]),
        EmojiItem(id: "keyboard", emoji: "⌨️", keywords: ["type", "computer", "input"]),
        EmojiItem(id: "camera", emoji: "📷", keywords: ["photo", "picture"]),
        EmojiItem(id: "book", emoji: "📖", keywords: ["read", "pages", "library"]),
        EmojiItem(id: "books", emoji: "📚", keywords: ["read", "library", "study"]),
        EmojiItem(id: "pencil", emoji: "✏️", keywords: ["write", "draw", "edit"]),
        EmojiItem(id: "pen", emoji: "🖊️", keywords: ["write", "sign"]),
        EmojiItem(id: "memo", emoji: "📝", keywords: ["note", "write", "document"]),
        EmojiItem(id: "calendar", emoji: "📅", keywords: ["date", "schedule", "event"]),
        EmojiItem(id: "folder", emoji: "📁", keywords: ["file", "organize", "directory"]),
        EmojiItem(id: "link", emoji: "🔗", keywords: ["url", "chain", "connect"]),
        EmojiItem(id: "bulb", emoji: "💡", keywords: ["idea", "light", "bright"]),
        EmojiItem(id: "gear", emoji: "⚙️", keywords: ["settings", "config", "cog"]),
        EmojiItem(id: "lock", emoji: "🔒", keywords: ["secure", "private", "closed"]),
        EmojiItem(id: "unlock", emoji: "🔓", keywords: ["open", "access"]),
        EmojiItem(id: "key", emoji: "🔑", keywords: ["unlock", "password", "access"]),
        EmojiItem(id: "hammer", emoji: "🔨", keywords: ["tool", "build", "fix"]),
        EmojiItem(id: "wrench", emoji: "🔧", keywords: ["tool", "fix", "repair"]),

        // Symbols & Status
        EmojiItem(id: "check", emoji: "✅", keywords: ["done", "complete", "yes", "success"]),
        EmojiItem(id: "x", emoji: "❌", keywords: ["no", "wrong", "error", "cancel"]),
        EmojiItem(id: "question", emoji: "❓", keywords: ["help", "what", "ask"]),
        EmojiItem(id: "exclamation", emoji: "❗", keywords: ["alert", "important", "attention"]),
        EmojiItem(id: "warning", emoji: "⚠️", keywords: ["caution", "alert", "danger"]),
        EmojiItem(id: "info", emoji: "ℹ️", keywords: ["information", "help", "about"]),
        EmojiItem(id: "plus", emoji: "➕", keywords: ["add", "new", "more"]),
        EmojiItem(id: "minus", emoji: "➖", keywords: ["remove", "subtract", "less"]),
        EmojiItem(id: "arrow_right", emoji: "➡️", keywords: ["direction", "next", "forward"]),
        EmojiItem(id: "arrow_left", emoji: "⬅️", keywords: ["direction", "back", "previous"]),
        EmojiItem(id: "arrow_up", emoji: "⬆️", keywords: ["direction", "up"]),
        EmojiItem(id: "arrow_down", emoji: "⬇️", keywords: ["direction", "down"]),
        EmojiItem(id: "recycle", emoji: "♻️", keywords: ["green", "environment", "reuse"]),

        // Weather & Nature
        EmojiItem(id: "sun", emoji: "☀️", keywords: ["weather", "bright", "day"]),
        EmojiItem(id: "moon", emoji: "🌙", keywords: ["night", "sleep", "dark"]),
        EmojiItem(id: "cloud", emoji: "☁️", keywords: ["weather", "sky"]),
        EmojiItem(id: "rain", emoji: "🌧️", keywords: ["weather", "water", "wet"]),
        EmojiItem(id: "snow", emoji: "❄️", keywords: ["cold", "winter", "ice"]),
        EmojiItem(id: "rainbow", emoji: "🌈", keywords: ["color", "weather", "pride"]),
        EmojiItem(id: "tree", emoji: "🌲", keywords: ["nature", "forest", "green"]),
        EmojiItem(id: "flower", emoji: "🌸", keywords: ["nature", "pretty", "spring"]),
        EmojiItem(id: "rose", emoji: "🌹", keywords: ["flower", "love", "red"]),
        EmojiItem(id: "earth", emoji: "🌍", keywords: ["world", "globe", "planet"]),

        // Activities & Celebrations
        EmojiItem(id: "trophy", emoji: "🏆", keywords: ["win", "award", "champion"]),
        EmojiItem(id: "medal", emoji: "🏅", keywords: ["win", "award", "achievement"]),
        EmojiItem(id: "party", emoji: "🎉", keywords: ["celebrate", "tada", "confetti"]),
        EmojiItem(id: "gift", emoji: "🎁", keywords: ["present", "birthday", "wrap"]),
        EmojiItem(id: "balloon", emoji: "🎈", keywords: ["party", "celebrate", "birthday"]),
        EmojiItem(id: "rocket", emoji: "🚀", keywords: ["launch", "space", "fast", "ship"]),
        EmojiItem(id: "airplane", emoji: "✈️", keywords: ["travel", "fly", "plane"]),
        EmojiItem(id: "car", emoji: "🚗", keywords: ["drive", "vehicle", "auto"]),
        EmojiItem(id: "house", emoji: "🏠", keywords: ["home", "building"]),

        // Time
        EmojiItem(id: "hourglass", emoji: "⏳", keywords: ["time", "wait", "loading"]),
        EmojiItem(id: "watch", emoji: "⌚", keywords: ["time", "clock"]),
        EmojiItem(id: "alarm", emoji: "⏰", keywords: ["time", "wake", "clock"]),
    ]

    static func filtered(by query: String) -> [EmojiItem] {
        if query.isEmpty { return Array(all.prefix(20)) }  // Show first 20 when no query
        let lower = query.lowercased()
        return all.filter { item in
            item.id.contains(lower) || item.keywords.contains { $0.contains(lower) }
        }
    }
}

// MARK: - NSTextView wrapper with Find/Replace

struct FindableTextEditor: NSViewRepresentable {
    @Binding var text: String
    @Binding var slashState: SlashCommandState
    @Binding var emojiState: EmojiState
    let documentURL: () -> URL?

    // Editor settings from AppStorage
    @AppStorage(SettingsKeys.editorFontSize) private var fontSize: Double = 14
    @AppStorage(SettingsKeys.editorFontFamily) private var fontFamily: String = "System Mono"
    @AppStorage(SettingsKeys.editorLineHeight) private var lineHeight: Double = 1.4
    @AppStorage(SettingsKeys.editorSyntaxHighlighting) private var syntaxHighlighting: Bool = true
    @AppStorage(SettingsKeys.editorSpellCheck) private var spellCheck: Bool = false
    @AppStorage(SettingsKeys.editorFocusMode) private var focusMode: Bool = false
    @AppStorage(SettingsKeys.editorAutoPairs) private var autoPairs: Bool = true
    @AppStorage(SettingsKeys.editorSmartLists) private var smartLists: Bool = true

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    private func getFont() -> NSFont {
        let fontName: String
        switch fontFamily {
        case "System Mono": fontName = ".AppleSystemUIFontMonospaced"
        case "Menlo": fontName = "Menlo"
        case "Monaco": fontName = "Monaco"
        case "SF Mono": fontName = "SFMono-Regular"
        case "JetBrains Mono": fontName = "JetBrainsMono-Regular"
        case "Fira Code": fontName = "FiraCode-Regular"
        case "Source Code Pro": fontName = "SourceCodePro-Regular"
        default: fontName = ".AppleSystemUIFontMonospaced"
        }

        if fontName == ".AppleSystemUIFontMonospaced" {
            return NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        }

        return NSFont(name: fontName, size: fontSize)
            ?? NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder

        let textView = SlashTextView()
        textView.isEditable = true
        textView.isSelectable = true
        textView.isRichText = false
        textView.allowsUndo = true
        textView.usesFontPanel = false
        textView.usesFindBar = true
        textView.isIncrementalSearchingEnabled = true
        textView.font = getFont()
        textView.textColor = NSColor.labelColor
        textView.backgroundColor = NSColor.textBackgroundColor
        textView.drawsBackground = true
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainerInset = NSSize(width: 16, height: 20)
        textView.autoresizingMask = [.width]
        textView.delegate = context.coordinator
        textView.coordinator = context.coordinator

        // Apply line height
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = lineHeight
        textView.defaultParagraphStyle = paragraphStyle
        textView.typingAttributes[.paragraphStyle] = paragraphStyle

        textView.textContainer?.containerSize = NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true

        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isGrammarCheckingEnabled = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isContinuousSpellCheckingEnabled = spellCheck
        textView.autoPairsEnabled = autoPairs
        textView.smartListsEnabled = smartLists

        scrollView.documentView = textView
        context.coordinator.textView = textView
        context.coordinator.syntaxHighlightingEnabled = syntaxHighlighting
        context.coordinator.focusModeEnabled = focusMode
        slashState.textView = textView

        // Wire up document URL closure for image handling
        textView.getDocumentURL = documentURL

        textView.string = text

        // Apply initial syntax highlighting
        if syntaxHighlighting, let textStorage = textView.textStorage {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineHeightMultiple = lineHeight
            SyntaxHighlighter.highlight(textStorage, baseFont: getFont(), paragraphStyle: paragraphStyle)
        }

        DispatchQueue.main.async {
            textView.window?.makeFirstResponder(textView)
        }

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }

        // Update font if settings changed
        let newFont = getFont()
        if textView.font != newFont {
            textView.font = newFont
        }

        // Update line height if settings changed
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = lineHeight
        if let currentStyle = textView.defaultParagraphStyle,
           currentStyle.lineHeightMultiple != lineHeight {
            textView.defaultParagraphStyle = paragraphStyle
            textView.typingAttributes[.paragraphStyle] = paragraphStyle
            // Re-apply to existing text
            if let textStorage = textView.textStorage, textStorage.length > 0 {
                textStorage.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: textStorage.length))
            }
        }

        // Update syntax highlighting setting
        if context.coordinator.syntaxHighlightingEnabled != syntaxHighlighting {
            context.coordinator.syntaxHighlightingEnabled = syntaxHighlighting
            // Re-apply highlighting if toggled on
            if syntaxHighlighting, let textStorage = textView.textStorage {
                SyntaxHighlighter.highlight(textStorage, baseFont: newFont, paragraphStyle: paragraphStyle)
            } else if let textStorage = textView.textStorage {
                // Reset to plain text if turned off
                let fullRange = NSRange(location: 0, length: textStorage.length)
                textStorage.beginEditing()
                textStorage.setAttributes([
                    .font: newFont,
                    .foregroundColor: NSColor.labelColor,
                    .paragraphStyle: paragraphStyle
                ], range: fullRange)
                textStorage.endEditing()
            }
        }

        // Update spell check setting
        if textView.isContinuousSpellCheckingEnabled != spellCheck {
            textView.isContinuousSpellCheckingEnabled = spellCheck
        }

        // Update focus mode setting
        if context.coordinator.focusModeEnabled != focusMode {
            context.coordinator.focusModeEnabled = focusMode
            if focusMode {
                context.coordinator.applyFocusMode(to: textView)
            } else {
                context.coordinator.clearFocusMode(from: textView)
            }
        }

        // Update auto-pairs and smart lists settings
        if let slashTextView = textView as? SlashTextView {
            slashTextView.autoPairsEnabled = autoPairs
            slashTextView.smartListsEnabled = smartLists
        }

        if textView.string != text && !context.coordinator.isEditing {
            let selectedRanges = textView.selectedRanges
            textView.string = text
            textView.selectedRanges = selectedRanges

            // Apply highlighting to new content
            if syntaxHighlighting, let textStorage = textView.textStorage {
                SyntaxHighlighter.highlight(textStorage, baseFont: newFont, paragraphStyle: paragraphStyle)
            }
        }
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: FindableTextEditor
        weak var textView: NSTextView?
        var isEditing = false
        var syntaxHighlightingEnabled = true
        var focusModeEnabled = false
        var highlightWorkItem: DispatchWorkItem?
        var focusWorkItem: DispatchWorkItem?
        var slashMenuWindow: NSWindow?
        var slashMenuController: SlashMenuController?
        var emojiMenuWindow: NSWindow?
        var emojiMenuController: EmojiMenuController?

        init(_ parent: FindableTextEditor) {
            self.parent = parent
            super.init()
        }

        func textDidBeginEditing(_ notification: Notification) {
            isEditing = true
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }

            // Apply focus mode when cursor moves
            applyFocusModeDebounced(to: textView)
        }

        func textDidEndEditing(_ notification: Notification) {
            isEditing = false
            dismissSlashMenu()
            dismissEmojiMenu()
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string

            // Check for slash command trigger
            checkForSlashCommand(in: textView)

            // Check for emoji trigger (only if slash menu not active)
            if !parent.slashState.isActive {
                checkForEmojiTrigger(in: textView)
            }

            // Apply syntax highlighting with debouncing
            applyHighlightingDebounced(to: textView)
        }

        private func applyHighlightingDebounced(to textView: NSTextView) {
            guard syntaxHighlightingEnabled else { return }
            guard let textStorage = textView.textStorage else { return }

            // Cancel any pending highlight work
            highlightWorkItem?.cancel()

            // Capture current values
            let font = parent.getFont()
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineHeightMultiple = parent.lineHeight

            // Store cursor position to restore after highlighting
            let selectedRanges = textView.selectedRanges

            // Debounce highlighting - wait until user stops typing (300ms)
            let workItem = DispatchWorkItem { [weak textStorage, weak textView] in
                guard let storage = textStorage, let tv = textView else { return }

                // Temporarily disable undo grouping during highlighting
                tv.undoManager?.disableUndoRegistration()

                SyntaxHighlighter.highlight(storage, baseFont: font, paragraphStyle: paragraphStyle)

                // Restore cursor position
                tv.selectedRanges = selectedRanges

                tv.undoManager?.enableUndoRegistration()
            }
            highlightWorkItem = workItem

            // Longer delay so highlighting only happens when user pauses (300ms)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: workItem)
        }

        // MARK: - Focus Mode

        func applyFocusMode(to textView: NSTextView) {
            guard focusModeEnabled else { return }
            guard let textStorage = textView.textStorage else { return }
            guard textStorage.length > 0 else { return }

            let text = textStorage.string
            let nsString = text as NSString
            let cursorLocation = textView.selectedRange().location

            // Find the current paragraph range
            let currentParagraphRange = nsString.paragraphRange(for: NSRange(location: min(cursorLocation, nsString.length - 1), length: 0))

            // Dim all text first
            let fullRange = NSRange(location: 0, length: textStorage.length)
            textStorage.addAttribute(.foregroundColor, value: NSColor.labelColor.withAlphaComponent(0.3), range: fullRange)

            // Restore full opacity for current paragraph
            if currentParagraphRange.location != NSNotFound && currentParagraphRange.length > 0 {
                textStorage.addAttribute(.foregroundColor, value: NSColor.labelColor, range: currentParagraphRange)
            }
        }

        func clearFocusMode(from textView: NSTextView) {
            guard let textStorage = textView.textStorage else { return }
            guard textStorage.length > 0 else { return }

            let fullRange = NSRange(location: 0, length: textStorage.length)
            textStorage.addAttribute(.foregroundColor, value: NSColor.labelColor, range: fullRange)

            // Re-apply syntax highlighting if enabled
            if syntaxHighlightingEnabled {
                let font = parent.getFont()
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.lineHeightMultiple = parent.lineHeight
                SyntaxHighlighter.highlight(textStorage, baseFont: font, paragraphStyle: paragraphStyle)
            }
        }

        private func applyFocusModeDebounced(to textView: NSTextView) {
            guard focusModeEnabled else { return }

            // Cancel any pending focus work
            focusWorkItem?.cancel()

            let workItem = DispatchWorkItem { [weak self, weak textView] in
                guard let tv = textView else { return }
                self?.applyFocusMode(to: tv)
            }
            focusWorkItem = workItem

            // Small delay (100ms) to avoid flicker during rapid cursor movement
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: workItem)
        }

        func checkForSlashCommand(in textView: NSTextView) {
            let text = textView.string
            let cursorLocation = textView.selectedRange().location

            guard cursorLocation > 0 else {
                dismissSlashMenu()
                return
            }

            // Find the start of the current line
            let nsString = text as NSString
            let lineRange = nsString.lineRange(for: NSRange(location: cursorLocation - 1, length: 0))
            let lineStart = lineRange.location
            let lineText = nsString.substring(with: NSRange(location: lineStart, length: cursorLocation - lineStart))

            // Check if line starts with /
            if lineText.hasPrefix("/") {
                let query = String(lineText.dropFirst())
                let slashRange = NSRange(location: lineStart, length: cursorLocation - lineStart)

                // Get position for menu
                let glyphRange = textView.layoutManager?.glyphRange(forCharacterRange: NSRange(location: cursorLocation, length: 0), actualCharacterRange: nil) ?? NSRange()
                var rect = textView.layoutManager?.boundingRect(forGlyphRange: glyphRange, in: textView.textContainer!) ?? .zero
                rect.origin.x += textView.textContainerInset.width
                rect.origin.y += textView.textContainerInset.height

                let windowPoint = textView.convert(rect.origin, to: nil)
                let screenPoint = textView.window?.convertPoint(toScreen: windowPoint) ?? .zero

                showSlashMenu(at: screenPoint, query: query, slashRange: slashRange)
            } else {
                dismissSlashMenu()
            }
        }

        func showSlashMenu(at point: NSPoint, query: String, slashRange: NSRange) {
            // Early exit if query hasn't changed and menu is already showing
            // This avoids unnecessary filtering and state updates on each keystroke
            if slashMenuWindow != nil && parent.slashState.query == query {
                // Just update the range for insertion
                parent.slashState.slashRange = slashRange
                return
            }

            let commands = SlashCommandRegistry.syncShared.filtered(by: query)
            guard !commands.isEmpty else {
                dismissSlashMenu()
                return
            }

            // Store the current range - always use this when inserting
            parent.slashState.slashRange = slashRange

            if slashMenuWindow == nil {
                let controller = SlashMenuController(commands: commands) { [weak self] command in
                    // Always use the current slashRange from state, not the captured one
                    guard let currentRange = self?.parent.slashState.slashRange else { return }
                    self?.insertSlashCommand(command, range: currentRange)
                }
                self.slashMenuController = controller

                let window = NSPanel(
                    contentRect: NSRect(x: 0, y: 0, width: 280, height: min(CGFloat(commands.count * 44) + 8, 300)),
                    styleMask: [.nonactivatingPanel],
                    backing: .buffered,
                    defer: false
                )
                window.isFloatingPanel = true
                window.level = .floating
                window.backgroundColor = .clear
                window.isOpaque = false
                window.hasShadow = true

                let hostingView = NSHostingView(rootView:
                    SlashMenuView(controller: controller, onSelect: { [weak self] command in
                        guard let currentRange = self?.parent.slashState.slashRange else { return }
                        self?.insertSlashCommand(command, range: currentRange)
                    })
                )
                window.contentView = hostingView

                self.slashMenuWindow = window
            } else {
                // Update existing controller with new commands
                slashMenuController?.updateCommands(commands, slashRange: slashRange)
            }

            // Update window height based on command count and position
            if let window = slashMenuWindow, let screen = NSScreen.main {
                let menuHeight = min(CGFloat(commands.count * 44) + 8, 300)
                let lineHeight: CGFloat = 20 // Approximate line height

                // Check if there's enough space below the cursor
                let spaceBelow = point.y - screen.visibleFrame.origin.y
                let showAbove = spaceBelow < menuHeight + 20

                var frame = window.frame
                frame.size.height = menuHeight

                if showAbove {
                    // Position above the cursor
                    frame.origin.x = point.x
                    frame.origin.y = point.y + lineHeight
                } else {
                    // Position below the cursor (original behavior)
                    frame.origin.x = point.x
                    frame.origin.y = point.y - menuHeight - 4
                }

                window.setFrame(frame, display: true)
            }

            slashMenuWindow?.orderFront(nil)
            parent.slashState.isActive = true
            parent.slashState.query = query
        }

        func dismissSlashMenu() {
            // Early exit if already dismissed to avoid unnecessary state updates
            guard slashMenuWindow != nil || parent.slashState.isActive else { return }

            slashMenuWindow?.orderOut(nil)
            slashMenuWindow = nil
            slashMenuController = nil
            parent.slashState.isActive = false
            parent.slashState.query = ""
            parent.slashState.slashRange = nil
        }

        func insertSlashCommand(_ command: SlashCommand, range: NSRange) {
            guard let textView = textView else { return }

            var insertText = command.insert

            // Handle date picker
            if insertText == "{{DATEPICKER}}" {
                dismissSlashMenu()
                showDatePicker(range: range)
                return
            }

            // Handle frontmatter commands
            if insertText.hasPrefix("{{FRONTMATTER:") {
                dismissSlashMenu()
                // Remove the slash command text first
                if textView.shouldChangeText(in: range, replacementString: "") {
                    textView.replaceCharacters(in: range, with: "")
                    textView.didChangeText()
                }
                handleFrontmatterCommand(insertText)
                SlashCommandRegistry.syncShared.recordUsage(command.id)
                return
            }

            // Handle date/time placeholders
            let now = Date()
            let dateFormatter = DateFormatter()

            // Replace {{DATE:format}} placeholders
            let datePattern = try? NSRegularExpression(pattern: "\\{\\{DATE:([^}]+)\\}\\}", options: [])
            if let matches = datePattern?.matches(in: insertText, options: [], range: NSRange(insertText.startIndex..., in: insertText)) {
                for match in matches.reversed() {
                    if let formatRange = Range(match.range(at: 1), in: insertText),
                       let fullRange = Range(match.range, in: insertText) {
                        let format = String(insertText[formatRange])
                        dateFormatter.dateFormat = format
                        let dateString = dateFormatter.string(from: now)
                        insertText.replaceSubrange(fullRange, with: dateString)
                    }
                }
            }

            // Replace {{TIME:format}} placeholders
            let timePattern = try? NSRegularExpression(pattern: "\\{\\{TIME:([^}]+)\\}\\}", options: [])
            if let matches = timePattern?.matches(in: insertText, options: [], range: NSRange(insertText.startIndex..., in: insertText)) {
                for match in matches.reversed() {
                    if let formatRange = Range(match.range(at: 1), in: insertText),
                       let fullRange = Range(match.range, in: insertText) {
                        let format = String(insertText[formatRange])
                        dateFormatter.dateFormat = format
                        let timeString = dateFormatter.string(from: now)
                        insertText.replaceSubrange(fullRange, with: timeString)
                    }
                }
            }

            // Handle cursor placeholder
            let cursorPlaceholder = "{{CURSOR}}"
            var cursorOffset: Int? = nil
            if let placeholderRange = insertText.range(of: cursorPlaceholder) {
                cursorOffset = insertText.distance(from: insertText.startIndex, to: placeholderRange.lowerBound)
                insertText = insertText.replacingOccurrences(of: cursorPlaceholder, with: "")
            }

            // Replace the slash command text with the insert text
            if textView.shouldChangeText(in: range, replacementString: insertText) {
                textView.replaceCharacters(in: range, with: insertText)
                textView.didChangeText()

                // Position cursor appropriately
                let newLocation: Int
                if let offset = cursorOffset {
                    newLocation = range.location + offset
                } else {
                    newLocation = range.location + insertText.count
                }
                textView.setSelectedRange(NSRange(location: newLocation, length: 0))
            }

            // Track usage for recent commands
            SlashCommandRegistry.syncShared.recordUsage(command.id)

            dismissSlashMenu()
        }

        private var datePickerWindow: NSWindow?
        private var pendingDateRange: NSRange?

        func showDatePicker(range: NSRange) {
            guard let textView = textView, let window = textView.window else { return }

            pendingDateRange = range

            // Calculate position below cursor
            let glyphRange = textView.layoutManager?.glyphRange(forCharacterRange: range, actualCharacterRange: nil) ?? NSRange()
            var rect = textView.layoutManager?.boundingRect(forGlyphRange: glyphRange, in: textView.textContainer!) ?? .zero
            rect.origin.x += textView.textContainerInset.width
            rect.origin.y += textView.textContainerInset.height

            let windowPoint = textView.convert(rect.origin, to: nil)
            let screenPoint = window.convertPoint(toScreen: windowPoint)

            // Create date picker panel
            let panel = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 240, height: 280),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            panel.title = "Pick Date"
            panel.isFloatingPanel = true
            panel.level = .floating
            panel.becomesKeyOnlyIfNeeded = true

            let hostingView = NSHostingView(rootView:
                DatePickerView(
                    onSelect: { [weak self] date in
                        self?.insertDate(date)
                        self?.datePickerWindow?.close()
                        self?.datePickerWindow = nil
                    },
                    onCancel: { [weak self] in
                        // Remove the slash command text on cancel
                        if let range = self?.pendingDateRange, let tv = self?.textView {
                            if tv.shouldChangeText(in: range, replacementString: "") {
                                tv.replaceCharacters(in: range, with: "")
                                tv.didChangeText()
                            }
                        }
                        self?.datePickerWindow?.close()
                        self?.datePickerWindow = nil
                    }
                )
            )
            panel.contentView = hostingView

            // Position below cursor
            panel.setFrameTopLeftPoint(NSPoint(x: screenPoint.x, y: screenPoint.y - 4))

            datePickerWindow = panel
            panel.makeKeyAndOrderFront(nil)
        }

        func insertDate(_ date: Date) {
            guard let textView = textView, let range = pendingDateRange else { return }

            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let dateString = formatter.string(from: date)

            if textView.shouldChangeText(in: range, replacementString: dateString) {
                textView.replaceCharacters(in: range, with: dateString)
                textView.didChangeText()
                textView.setSelectedRange(NSRange(location: range.location + dateString.count, length: 0))
            }

            pendingDateRange = nil
        }

        // MARK: - Frontmatter Commands

        func handleFrontmatterCommand(_ command: String) {
            guard let textView = textView else { return }

            // Extract the command type from {{FRONTMATTER:type}}
            let pattern = try? NSRegularExpression(pattern: "\\{\\{FRONTMATTER:([^}]+)\\}\\}", options: [])
            guard let match = pattern?.firstMatch(in: command, options: [], range: NSRange(command.startIndex..., in: command)),
                  let typeRange = Range(match.range(at: 1), in: command) else { return }

            let commandType = String(command[typeRange])

            switch commandType {
            case "jekyll":
                insertJekyllFrontmatter(textView: textView)
            case "hugo":
                insertHugoFrontmatter(textView: textView)
            case "toggle-draft":
                toggleDraftStatus(textView: textView)
            case "inspector":
                NotificationCenter.default.post(name: .toggleInspector, object: nil)
            default:
                break
            }
        }

        private func insertJekyllFrontmatter(textView: NSTextView) {
            let content = textView.string
            let (existingFrontmatter, _) = Frontmatter.parse(from: content)

            // Don't add if frontmatter already exists
            if existingFrontmatter != nil { return }

            // Get defaults from settings
            let jekyllAuthor = UserDefaults.standard.string(forKey: SettingsKeys.jekyllDefaultAuthor) ?? ""
            let jekyllLayout = UserDefaults.standard.string(forKey: SettingsKeys.jekyllDefaultLayout) ?? "post"
            let jekyllDraft = UserDefaults.standard.bool(forKey: SettingsKeys.jekyllDefaultDraft)
            let jekyllTags = UserDefaults.standard.string(forKey: SettingsKeys.jekyllDefaultTags) ?? ""
            let jekyllCategories = UserDefaults.standard.string(forKey: SettingsKeys.jekyllDefaultCategories) ?? ""

            var fm = Frontmatter(format: .yaml)
            // Get title from document URL or use default
            let title = parent.documentURL()?.deletingPathExtension().lastPathComponent ?? "Untitled"
            fm.title = title
            fm.date = Date()
            fm.draft = jekyllDraft
            if !jekyllAuthor.isEmpty { fm.author = jekyllAuthor }
            if !jekyllLayout.isEmpty { fm.layout = jekyllLayout }
            if !jekyllTags.isEmpty {
                fm.tags = jekyllTags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            }
            if !jekyllCategories.isEmpty {
                fm.categories = jekyllCategories.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            }

            let frontmatterStr = fm.toString() + "\n\n"
            let range = NSRange(location: 0, length: 0)

            if textView.shouldChangeText(in: range, replacementString: frontmatterStr) {
                textView.replaceCharacters(in: range, with: frontmatterStr)
                textView.didChangeText()
                // Move cursor to end of frontmatter
                textView.setSelectedRange(NSRange(location: frontmatterStr.count, length: 0))
            }
        }

        private func insertHugoFrontmatter(textView: NSTextView) {
            let content = textView.string
            let (existingFrontmatter, _) = Frontmatter.parse(from: content)

            // Don't add if frontmatter already exists
            if existingFrontmatter != nil { return }

            // Get defaults from settings
            let hugoFormat = UserDefaults.standard.string(forKey: SettingsKeys.hugoDefaultFormat) ?? "yaml"
            let hugoAuthor = UserDefaults.standard.string(forKey: SettingsKeys.hugoDefaultAuthor) ?? ""
            let hugoLayout = UserDefaults.standard.string(forKey: SettingsKeys.hugoDefaultLayout) ?? ""
            let hugoDraft = UserDefaults.standard.bool(forKey: SettingsKeys.hugoDefaultDraft)
            let hugoTags = UserDefaults.standard.string(forKey: SettingsKeys.hugoDefaultTags) ?? ""
            let hugoCategories = UserDefaults.standard.string(forKey: SettingsKeys.hugoDefaultCategories) ?? ""

            let format: FrontmatterFormat = hugoFormat == "toml" ? .toml : .yaml
            var fm = Frontmatter(format: format)
            // Get title from document URL or use default
            let title = parent.documentURL()?.deletingPathExtension().lastPathComponent ?? "Untitled"
            fm.title = title
            fm.date = Date()
            fm.draft = hugoDraft
            if !hugoAuthor.isEmpty { fm.author = hugoAuthor }
            if !hugoLayout.isEmpty { fm.layout = hugoLayout }
            if !hugoTags.isEmpty {
                fm.tags = hugoTags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            }
            if !hugoCategories.isEmpty {
                fm.categories = hugoCategories.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            }

            let frontmatterStr = fm.toString() + "\n\n"
            let range = NSRange(location: 0, length: 0)

            if textView.shouldChangeText(in: range, replacementString: frontmatterStr) {
                textView.replaceCharacters(in: range, with: frontmatterStr)
                textView.didChangeText()
                textView.setSelectedRange(NSRange(location: frontmatterStr.count, length: 0))
            }
        }

        private func toggleDraftStatus(textView: NSTextView) {
            let content = textView.string
            let (frontmatter, body) = Frontmatter.parse(from: content)

            guard var fm = frontmatter else { return }

            // Toggle draft status
            fm.draft = !fm.draft

            // Rebuild the document
            let newContent = fm.apply(to: body)

            // Replace entire content
            let fullRange = NSRange(location: 0, length: (content as NSString).length)
            if textView.shouldChangeText(in: fullRange, replacementString: newContent) {
                textView.replaceCharacters(in: fullRange, with: newContent)
                textView.didChangeText()
            }
        }

        func handleSlashMenuKeyDown(_ event: NSEvent) -> Bool {
            guard parent.slashState.isActive else { return false }

            switch event.keyCode {
            case 53: // Escape
                dismissSlashMenu()
                return true
            case 36: // Return
                if let controller = slashMenuController {
                    controller.selectCurrent()
                    return true
                }
            case 125: // Down arrow
                slashMenuController?.moveDown()
                return true
            case 126: // Up arrow
                slashMenuController?.moveUp()
                return true
            default:
                break
            }
            return false
        }

        // MARK: - Emoji Picker

        func checkForEmojiTrigger(in textView: NSTextView) {
            let text = textView.string
            let cursorLocation = textView.selectedRange().location

            guard cursorLocation > 0 else {
                dismissEmojiMenu()
                return
            }

            // Look backwards for a colon that starts an emoji shortcode
            let nsString = text as NSString
            var colonLocation: Int? = nil
            var query = ""

            // Search backwards from cursor for opening colon
            for i in stride(from: cursorLocation - 1, through: max(0, cursorLocation - 30), by: -1) {
                let char = nsString.character(at: i)
                let charStr = String(UnicodeScalar(char)!)

                if charStr == ":" {
                    // Found colon - check it's not preceded by another colon (closing a previous emoji)
                    if i > 0 {
                        let prevChar = nsString.character(at: i - 1)
                        if prevChar == UnicodeScalar(":").value {
                            // This is a closing colon, not an opening one
                            dismissEmojiMenu()
                            return
                        }
                    }
                    colonLocation = i
                    break
                } else if charStr == " " || charStr == "\n" || charStr == "\t" {
                    // Hit whitespace before finding colon
                    dismissEmojiMenu()
                    return
                } else if charStr.rangeOfCharacter(from: CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_"))) == nil {
                    // Hit non-alphanumeric character
                    dismissEmojiMenu()
                    return
                }
            }

            guard let colonLoc = colonLocation else {
                dismissEmojiMenu()
                return
            }

            // Extract query (text after colon)
            let queryRange = NSRange(location: colonLoc + 1, length: cursorLocation - colonLoc - 1)
            query = nsString.substring(with: queryRange)

            // Only show picker if we have at least 1 character after colon
            guard query.count >= 1 else {
                dismissEmojiMenu()
                return
            }

            let colonRange = NSRange(location: colonLoc, length: cursorLocation - colonLoc)

            // Get position for menu
            let glyphRange = textView.layoutManager?.glyphRange(forCharacterRange: NSRange(location: cursorLocation, length: 0), actualCharacterRange: nil) ?? NSRange()
            var rect = textView.layoutManager?.boundingRect(forGlyphRange: glyphRange, in: textView.textContainer!) ?? .zero
            rect.origin.x += textView.textContainerInset.width
            rect.origin.y += textView.textContainerInset.height

            let windowPoint = textView.convert(rect.origin, to: nil)
            let screenPoint = textView.window?.convertPoint(toScreen: windowPoint) ?? .zero

            showEmojiMenu(at: screenPoint, query: query, colonRange: colonRange)
        }

        func showEmojiMenu(at point: NSPoint, query: String, colonRange: NSRange) {
            let emojis = EmojiItem.filtered(by: query)
            guard !emojis.isEmpty else {
                dismissEmojiMenu()
                return
            }

            parent.emojiState.colonRange = colonRange

            if emojiMenuWindow == nil {
                let controller = EmojiMenuController(emojis: emojis) { [weak self] emoji in
                    guard let currentRange = self?.parent.emojiState.colonRange else { return }
                    self?.insertEmoji(emoji, range: currentRange)
                }
                self.emojiMenuController = controller

                let window = NSPanel(
                    contentRect: NSRect(x: 0, y: 0, width: 280, height: min(CGFloat(emojis.count * 36) + 8, 250)),
                    styleMask: [.nonactivatingPanel],
                    backing: .buffered,
                    defer: false
                )
                window.isFloatingPanel = true
                window.level = .floating
                window.backgroundColor = .clear
                window.isOpaque = false
                window.hasShadow = true

                let hostingView = NSHostingView(rootView:
                    EmojiMenuView(controller: controller, onSelect: { [weak self] emoji in
                        guard let currentRange = self?.parent.emojiState.colonRange else { return }
                        self?.insertEmoji(emoji, range: currentRange)
                    })
                )
                window.contentView = hostingView

                self.emojiMenuWindow = window
            } else {
                emojiMenuController?.updateEmojis(emojis)
            }

            // Update position
            emojiMenuWindow?.setFrameTopLeftPoint(NSPoint(x: point.x, y: point.y - 4))

            // Update height
            if let window = emojiMenuWindow {
                var frame = window.frame
                let newHeight = min(CGFloat(emojis.count * 36) + 8, 250)
                frame.origin.y += frame.size.height - newHeight
                frame.size.height = newHeight
                window.setFrame(frame, display: true)
            }

            emojiMenuWindow?.orderFront(nil)
            parent.emojiState.isActive = true
            parent.emojiState.query = query
        }

        func dismissEmojiMenu() {
            emojiMenuWindow?.orderOut(nil)
            emojiMenuWindow = nil
            emojiMenuController = nil
            parent.emojiState.isActive = false
            parent.emojiState.query = ""
            parent.emojiState.colonRange = nil
        }

        func insertEmoji(_ emoji: EmojiItem, range: NSRange) {
            guard let textView = textView else { return }

            // Replace :shortcode with the actual emoji
            if textView.shouldChangeText(in: range, replacementString: emoji.emoji) {
                textView.replaceCharacters(in: range, with: emoji.emoji)
                textView.didChangeText()
                textView.setSelectedRange(NSRange(location: range.location + emoji.emoji.count, length: 0))
            }

            dismissEmojiMenu()
        }

        func handleEmojiMenuKeyDown(_ event: NSEvent) -> Bool {
            guard parent.emojiState.isActive else { return false }

            switch event.keyCode {
            case 53: // Escape
                dismissEmojiMenu()
                return true
            case 36: // Return
                if let controller = emojiMenuController {
                    controller.selectCurrent()
                    return true
                }
            case 125: // Down arrow
                emojiMenuController?.moveDown()
                return true
            case 126: // Up arrow
                emojiMenuController?.moveUp()
                return true
            default:
                break
            }
            return false
        }
    }
}

// MARK: - Custom NSTextView for slash commands and image handling

class SlashTextView: NSTextView {
    weak var coordinator: FindableTextEditor.Coordinator?
    var getDocumentURL: (() -> URL?)? = nil
    var autoPairsEnabled: Bool = true
    var smartListsEnabled: Bool = true

    // Auto-pair mappings
    private static let autoPairs: [String: String] = [
        "(": ")",
        "[": "]",
        "{": "}",
        "\"": "\"",
        "'": "'",
        "`": "`",
        "*": "*",
        "_": "_",
        "~": "~",
    ]

    // Characters that can be "skipped over" when closing
    private static let closingChars: Set<String> = [")", "]", "}", "\"", "'", "`", "*", "_", "~"]

    override func keyDown(with event: NSEvent) {
        if coordinator?.handleSlashMenuKeyDown(event) == true {
            return
        }
        if coordinator?.handleEmojiMenuKeyDown(event) == true {
            return
        }
        super.keyDown(with: event)
    }

    override func insertText(_ string: Any, replacementRange: NSRange) {
        guard autoPairsEnabled,
              let str = string as? String,
              str.count == 1 else {
            super.insertText(string, replacementRange: replacementRange)
            return
        }

        let selection = selectedRange()

        // Handle closing character skip-over
        if Self.closingChars.contains(str) {
            let nextCharRange = NSRange(location: selection.location, length: 1)
            if nextCharRange.location < self.string.count {
                let nextChar = (self.string as NSString).substring(with: nextCharRange)
                if nextChar == str {
                    // Skip over the existing closing character
                    setSelectedRange(NSRange(location: selection.location + 1, length: 0))
                    return
                }
            }
        }

        // Handle auto-pairing
        if let closingChar = Self.autoPairs[str] {
            // Check if we have selected text - wrap it
            if selection.length > 0 {
                let selectedText = (self.string as NSString).substring(with: selection)
                let wrappedText = str + selectedText + closingChar
                super.insertText(wrappedText, replacementRange: selection)
                // Position cursor after the opening char, selecting the wrapped text
                setSelectedRange(NSRange(location: selection.location + 1, length: selectedText.count))
                return
            }

            // No selection - insert pair and position cursor between
            let pair = str + closingChar
            super.insertText(pair, replacementRange: replacementRange)
            // Move cursor back one position (between the pair)
            setSelectedRange(NSRange(location: selection.location + 1, length: 0))
            return
        }

        super.insertText(string, replacementRange: replacementRange)
    }

    override func deleteBackward(_ sender: Any?) {
        // Handle auto-pair deletion (delete both characters if cursor is between a pair)
        if autoPairsEnabled {
            let selection = selectedRange()
            if selection.length == 0 && selection.location > 0 && selection.location < self.string.count {
                let prevCharRange = NSRange(location: selection.location - 1, length: 1)
                let nextCharRange = NSRange(location: selection.location, length: 1)
                let prevChar = (self.string as NSString).substring(with: prevCharRange)
                let nextChar = (self.string as NSString).substring(with: nextCharRange)

                if let expectedClose = Self.autoPairs[prevChar], expectedClose == nextChar {
                    // Delete both the opening and closing characters
                    let pairRange = NSRange(location: selection.location - 1, length: 2)
                    if shouldChangeText(in: pairRange, replacementString: "") {
                        replaceCharacters(in: pairRange, with: "")
                        didChangeText()
                    }
                    return
                }
            }
        }
        super.deleteBackward(sender)
    }

    override func insertNewline(_ sender: Any?) {
        guard smartListsEnabled else {
            super.insertNewline(sender)
            return
        }

        let cursorLocation = selectedRange().location
        let nsString = self.string as NSString
        let lineRange = nsString.lineRange(for: NSRange(location: cursorLocation, length: 0))
        let currentLine = nsString.substring(with: lineRange)

        // Check for bullet list: "- ", "* ", "+ " with optional leading whitespace
        let bulletPattern = "^(\\s*)([-*+])\\s"
        if let bulletRegex = try? NSRegularExpression(pattern: bulletPattern),
           let match = bulletRegex.firstMatch(in: currentLine, range: NSRange(currentLine.startIndex..., in: currentLine)) {
            let indent = (currentLine as NSString).substring(with: match.range(at: 1))
            let bullet = (currentLine as NSString).substring(with: match.range(at: 2))

            // Check if line only contains the bullet (empty item) - remove it
            let contentAfterBullet = currentLine.dropFirst(match.range.length).trimmingCharacters(in: .whitespacesAndNewlines)
            if contentAfterBullet.isEmpty {
                // Delete the empty list item and just add newline
                let deleteRange = NSRange(location: lineRange.location, length: lineRange.length)
                if shouldChangeText(in: deleteRange, replacementString: "\n") {
                    replaceCharacters(in: deleteRange, with: "\n")
                    didChangeText()
                }
                return
            }

            // Continue the list
            let continuation = "\n\(indent)\(bullet) "
            super.insertText(continuation, replacementRange: selectedRange())
            return
        }

        // Check for numbered list: "1. ", "2. " etc with optional leading whitespace
        let numberPattern = "^(\\s*)(\\d+)\\.\\s"
        if let numberRegex = try? NSRegularExpression(pattern: numberPattern),
           let match = numberRegex.firstMatch(in: currentLine, range: NSRange(currentLine.startIndex..., in: currentLine)) {
            let indent = (currentLine as NSString).substring(with: match.range(at: 1))
            let numberStr = (currentLine as NSString).substring(with: match.range(at: 2))
            let number = Int(numberStr) ?? 1

            // Check if line only contains the number (empty item) - remove it
            let contentAfterNumber = currentLine.dropFirst(match.range.length).trimmingCharacters(in: .whitespacesAndNewlines)
            if contentAfterNumber.isEmpty {
                // Delete the empty list item and just add newline
                let deleteRange = NSRange(location: lineRange.location, length: lineRange.length)
                if shouldChangeText(in: deleteRange, replacementString: "\n") {
                    replaceCharacters(in: deleteRange, with: "\n")
                    didChangeText()
                }
                return
            }

            // Continue the list with incremented number
            let continuation = "\n\(indent)\(number + 1). "
            super.insertText(continuation, replacementRange: selectedRange())
            return
        }

        // Check for task list: "- [ ] " or "- [x] " with optional leading whitespace
        let taskPattern = "^(\\s*-\\s\\[)[ xX](\\]\\s)"
        if let taskRegex = try? NSRegularExpression(pattern: taskPattern),
           let match = taskRegex.firstMatch(in: currentLine, range: NSRange(currentLine.startIndex..., in: currentLine)) {
            let prefix = (currentLine as NSString).substring(with: match.range(at: 1))

            // Check if line only contains the checkbox (empty item) - remove it
            let contentAfterCheckbox = currentLine.dropFirst(match.range.length).trimmingCharacters(in: .whitespacesAndNewlines)
            if contentAfterCheckbox.isEmpty {
                // Delete the empty task item and just add newline
                let deleteRange = NSRange(location: lineRange.location, length: lineRange.length)
                if shouldChangeText(in: deleteRange, replacementString: "\n") {
                    replaceCharacters(in: deleteRange, with: "\n")
                    didChangeText()
                }
                return
            }

            // Continue with unchecked task
            let continuation = "\n\(prefix) ] "
            super.insertText(continuation, replacementRange: selectedRange())
            return
        }

        super.insertNewline(sender)
    }

    // MARK: - Initializers

    convenience init() {
        self.init(frame: .zero)
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        registerForDraggedTypes([.fileURL, .png, .tiff, .URL])
    }

    override init(frame frameRect: NSRect, textContainer container: NSTextContainer?) {
        super.init(frame: frameRect, textContainer: container)
        registerForDraggedTypes([.fileURL, .png, .tiff, .URL])
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        registerForDraggedTypes([.fileURL, .png, .tiff, .URL])
    }

    // MARK: - Drag & Drop

    override func awakeFromNib() {
        super.awakeFromNib()
        registerForDraggedTypes([.fileURL, .png, .tiff])
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        if hasImageInDrag(sender) {
            return .copy
        }
        return super.draggingEntered(sender)
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let pasteboard = sender.draggingPasteboard

        // Handle file URLs (dragged image files)
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL] {
            let imageExtensions = ["png", "jpg", "jpeg", "gif", "webp", "svg", "bmp", "tiff"]
            let imageURLs = urls.filter { imageExtensions.contains($0.pathExtension.lowercased()) }

            if !imageURLs.isEmpty {
                for url in imageURLs {
                    insertImage(from: url)
                }
                return true
            }
        }

        // Handle image data directly (e.g., from other apps)
        if let imageData = pasteboard.data(forType: .png) ?? pasteboard.data(forType: .tiff) {
            insertImageData(imageData, extension: "png")
            return true
        }

        return super.performDragOperation(sender)
    }

    private func hasImageInDrag(_ sender: NSDraggingInfo) -> Bool {
        let pasteboard = sender.draggingPasteboard

        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL] {
            let imageExtensions = ["png", "jpg", "jpeg", "gif", "webp", "svg", "bmp", "tiff"]
            if urls.contains(where: { imageExtensions.contains($0.pathExtension.lowercased()) }) {
                return true
            }
        }

        if pasteboard.data(forType: .png) != nil || pasteboard.data(forType: .tiff) != nil {
            return true
        }

        return false
    }

    // MARK: - Paste

    override func paste(_ sender: Any?) {
        let pasteboard = NSPasteboard.general

        // Check for image data first
        if let imageData = pasteboard.data(forType: .png) ?? pasteboard.data(forType: .tiff) {
            insertImageData(imageData, extension: "png")
            return
        }

        // Check for image files
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL] {
            let imageExtensions = ["png", "jpg", "jpeg", "gif", "webp", "svg", "bmp", "tiff"]
            let imageURLs = urls.filter { imageExtensions.contains($0.pathExtension.lowercased()) }

            if !imageURLs.isEmpty {
                for url in imageURLs {
                    insertImage(from: url)
                }
                return
            }
        }

        // Default paste behavior for text
        super.paste(sender)
    }

    // MARK: - Image Insertion

    private func insertImage(from sourceURL: URL) {
        guard let docURL = documentURL() else {
            // No document saved yet - insert with absolute path
            let markdown = "![](file://\(sourceURL.path))"
            insertMarkdownAtCursor(markdown)
            return
        }

        // Create assets folder if needed
        let assetsFolder = docURL.deletingLastPathComponent().appendingPathComponent("assets")
        createAssetsFolderIfNeeded(at: assetsFolder)

        // Generate unique filename
        let filename = generateUniqueFilename(for: sourceURL.lastPathComponent, in: assetsFolder)
        let destinationURL = assetsFolder.appendingPathComponent(filename)

        // Copy file to assets folder
        do {
            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
            let markdown = "![](./assets/\(filename))"
            insertMarkdownAtCursor(markdown)
        } catch {
            // Fallback to absolute path
            let markdown = "![](file://\(sourceURL.path))"
            insertMarkdownAtCursor(markdown)
        }
    }

    private func insertImageData(_ data: Data, extension ext: String) {
        guard let docURL = documentURL() else {
            // Can't save image data without a document location
            // Show alert or just insert placeholder
            insertMarkdownAtCursor("![](paste image - save document first)")
            return
        }

        // Create assets folder if needed
        let assetsFolder = docURL.deletingLastPathComponent().appendingPathComponent("assets")
        createAssetsFolderIfNeeded(at: assetsFolder)

        // Generate unique filename with timestamp
        let timestamp = Int(Date().timeIntervalSince1970)
        let filename = "image-\(timestamp).\(ext)"
        let destinationURL = assetsFolder.appendingPathComponent(filename)

        // Write image data
        do {
            try data.write(to: destinationURL)
            let markdown = "![](./assets/\(filename))"
            insertMarkdownAtCursor(markdown)
        } catch {
            // Error saving pasted image - silently fail
        }
    }

    private func documentURL() -> URL? {
        return getDocumentURL?()
    }

    private func createAssetsFolderIfNeeded(at url: URL) {
        if !FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }

    private func generateUniqueFilename(for original: String, in folder: URL) -> String {
        let name = (original as NSString).deletingPathExtension
        let ext = (original as NSString).pathExtension

        var filename = original
        var counter = 1

        while FileManager.default.fileExists(atPath: folder.appendingPathComponent(filename).path) {
            filename = "\(name)-\(counter).\(ext)"
            counter += 1
        }

        return filename
    }

    private func insertMarkdownAtCursor(_ markdown: String) {
        let range = selectedRange()
        if shouldChangeText(in: range, replacementString: markdown) {
            replaceCharacters(in: range, with: markdown)
            didChangeText()
            setSelectedRange(NSRange(location: range.location + markdown.count, length: 0))
        }
    }
}

// MARK: - Slash Menu Controller

class SlashMenuController: ObservableObject {
    @Published var selectedIndex = 0
    @Published var commands: [SlashCommand]
    var onSelect: (SlashCommand) -> Void

    init(commands: [SlashCommand], onSelect: @escaping (SlashCommand) -> Void) {
        self.commands = commands
        self.onSelect = onSelect
    }

    func updateCommands(_ newCommands: [SlashCommand], slashRange: NSRange) {
        self.commands = newCommands
        if selectedIndex >= newCommands.count {
            selectedIndex = max(0, newCommands.count - 1)
        }
    }

    func moveDown() {
        if selectedIndex < commands.count - 1 {
            selectedIndex += 1
        }
    }

    func moveUp() {
        if selectedIndex > 0 {
            selectedIndex -= 1
        }
    }

    func selectCurrent() {
        guard selectedIndex < commands.count else { return }
        onSelect(commands[selectedIndex])
    }
}

// MARK: - Slash Menu View

struct SlashMenuView: View {
    @ObservedObject var controller: SlashMenuController
    let onSelect: (SlashCommand) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(controller.commands.enumerated()), id: \.element.id) { index, command in
                            SlashMenuRow(command: command, isSelected: index == controller.selectedIndex)
                                .id(command.id)
                                .onTapGesture {
                                    onSelect(command)
                                }
                                .onHover { hovering in
                                    if hovering {
                                        controller.selectedIndex = index
                                    }
                                }
                        }
                    }
                    .padding(4)
                }
                .onChange(of: controller.selectedIndex) { _, newIndex in
                    if controller.commands.indices.contains(newIndex) {
                        withAnimation(.easeInOut(duration: 0.1)) {
                            proxy.scrollTo(controller.commands[newIndex].id, anchor: .center)
                        }
                    }
                }
            }
        }
        .frame(width: 280, height: min(CGFloat(controller.commands.count * 44) + 8, 300))
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
        )
    }
}

struct SlashMenuRow: View {
    let command: SlashCommand
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: command.icon)
                .font(.system(size: 14))
                .foregroundColor(isSelected ? .white : .secondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 1) {
                Text(command.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isSelected ? .white : .primary)

                Text(command.description)
                    .font(.system(size: 11))
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
            }

            Spacer()

            Text("/\(command.id)")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(isSelected ? .white.opacity(0.7) : .secondary.opacity(0.6))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(isSelected ? Color.accentColor : Color.clear)
        .cornerRadius(6)
    }
}

// MARK: - Date Picker View

struct DatePickerView: View {
    @State private var selectedDate = Date()
    let onSelect: (Date) -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            DatePicker(
                "Select Date",
                selection: $selectedDate,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .labelsHidden()

            HStack(spacing: 12) {
                Button("Cancel") {
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)

                Button("Insert") {
                    onSelect(selectedDate)
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
            .padding(.bottom, 8)
        }
        .padding()
        .frame(width: 240)
    }
}

// MARK: - Emoji Menu Controller

class EmojiMenuController: ObservableObject {
    @Published var selectedIndex = 0
    @Published var emojis: [EmojiItem]
    var onSelect: (EmojiItem) -> Void

    init(emojis: [EmojiItem], onSelect: @escaping (EmojiItem) -> Void) {
        self.emojis = emojis
        self.onSelect = onSelect
    }

    func updateEmojis(_ newEmojis: [EmojiItem]) {
        self.emojis = newEmojis
        if selectedIndex >= newEmojis.count {
            selectedIndex = max(0, newEmojis.count - 1)
        }
    }

    func moveDown() {
        if selectedIndex < emojis.count - 1 {
            selectedIndex += 1
        }
    }

    func moveUp() {
        if selectedIndex > 0 {
            selectedIndex -= 1
        }
    }

    func selectCurrent() {
        guard selectedIndex < emojis.count else { return }
        onSelect(emojis[selectedIndex])
    }
}

// MARK: - Emoji Menu View

struct EmojiMenuView: View {
    @ObservedObject var controller: EmojiMenuController
    let onSelect: (EmojiItem) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(controller.emojis.enumerated()), id: \.element.id) { index, emoji in
                            EmojiMenuRow(emoji: emoji, isSelected: index == controller.selectedIndex)
                                .id(emoji.id)
                                .onTapGesture {
                                    onSelect(emoji)
                                }
                                .onHover { hovering in
                                    if hovering {
                                        controller.selectedIndex = index
                                    }
                                }
                        }
                    }
                    .padding(4)
                }
                .onChange(of: controller.selectedIndex) { _, newIndex in
                    if controller.emojis.indices.contains(newIndex) {
                        withAnimation(.easeInOut(duration: 0.1)) {
                            proxy.scrollTo(controller.emojis[newIndex].id, anchor: .center)
                        }
                    }
                }
            }
        }
        .frame(width: 280, height: min(CGFloat(controller.emojis.count * 36) + 8, 250))
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
        )
    }
}

struct EmojiMenuRow: View {
    let emoji: EmojiItem
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 10) {
            Text(emoji.emoji)
                .font(.system(size: 20))
                .frame(width: 28)

            Text(emoji.id)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(isSelected ? .white : .primary)

            Spacer()

            Text(":\(emoji.id):")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(isSelected ? .white.opacity(0.7) : .secondary.opacity(0.6))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(isSelected ? Color.accentColor : Color.clear)
        .cornerRadius(6)
    }
}
