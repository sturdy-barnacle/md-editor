//
//  PreviewView.swift
//  tibok
//
//  Live markdown preview using WKWebView.
//

import SwiftUI
import WebKit

struct PreviewView: View {
    @EnvironmentObject var appState: AppState

    // Preview settings
    @AppStorage(SettingsKeys.previewFontSize) private var fontSize: Double = 16
    @AppStorage(SettingsKeys.previewMaxWidth) private var maxWidth: Int = PreviewWidth.medium.rawValue
    @AppStorage(SettingsKeys.previewCodeTheme) private var codeTheme: String = CodeTheme.atom.rawValue

    /// Base URL for loading local resources (KaTeX)
    private var resourceBaseURL: URL? {
        Bundle.main.resourceURL
    }

    private var renderedHTML: String {
        var html = MarkdownRenderer.render(appState.currentDocument.content)

        // Convert local images to base64 data URLs if document is saved
        if let fileURL = appState.currentDocument.fileURL {
            html = convertLocalImagesToBase64(html, documentURL: fileURL)
        }

        return wrapInHTMLTemplate(html)
    }

    /// Converts local image paths to base64 data URLs
    private func convertLocalImagesToBase64(_ html: String, documentURL: URL) -> String {
        var result = html
        let documentDir = documentURL.deletingLastPathComponent()

        // Match img tags: <img src="..." alt="..." title="...">
        let pattern = #"<img\s+src="([^"]+)"#

        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return html
        }

        let matches = regex.matches(in: html, range: NSRange(html.startIndex..., in: html))

        // Process in reverse to maintain string indices
        for match in matches.reversed() {
            guard match.numberOfRanges >= 2,
                  let srcRange = Range(match.range(at: 1), in: html) else {
                continue
            }

            let srcPath = String(html[srcRange])

            // Skip if already a data URL or remote URL
            if srcPath.hasPrefix("data:") || srcPath.hasPrefix("http://") || srcPath.hasPrefix("https://") {
                continue
            }

            // Resolve local path
            var imageURL: URL
            if srcPath.hasPrefix("./") {
                imageURL = documentDir.appendingPathComponent(String(srcPath.dropFirst(2)))
            } else if srcPath.hasPrefix("/") {
                imageURL = URL(fileURLWithPath: srcPath)
            } else {
                imageURL = documentDir.appendingPathComponent(srcPath)
            }

            // Read image and convert to base64
            if let imageData = try? Data(contentsOf: imageURL) {
                // Determine MIME type from file extension
                let ext = imageURL.pathExtension.lowercased()
                let mimeType: String
                switch ext {
                case "png": mimeType = "image/png"
                case "jpg", "jpeg": mimeType = "image/jpeg"
                case "gif": mimeType = "image/gif"
                case "webp": mimeType = "image/webp"
                case "svg": mimeType = "image/svg+xml"
                default: mimeType = "image/\(ext)"
                }

                let base64 = imageData.base64EncodedString()
                let dataURL = "data:\(mimeType);base64,\(base64)"

                // Replace the src path with data URL
                result = result.replacingOccurrences(of: "src=\"\(srcPath)\"", with: "src=\"\(dataURL)\"")
            }
        }

        return result
    }

    var body: some View {
        VStack(spacing: 0) {
            if appState.currentDocument.isEmpty {
                // Empty state
                PreviewEmptyStateView()
            } else if !appState.currentDocument.isPreviewSupported {
                // Unsupported file type
                PreviewUnsupportedView(fileExtension: appState.currentDocument.fileURL?.pathExtension ?? "")
            } else {
                // Preview content using WKWebView
                MarkdownWebView(html: renderedHTML, baseURL: resourceBaseURL)
            }
        }
        .background(Color(NSColor.textBackgroundColor))
        .overlay(
            Rectangle()
                .fill(Color.primary.opacity(0.02))
                .allowsHitTesting(false)
        )
    }

    /// CSS max-width value based on settings
    private var maxWidthCSS: String {
        if maxWidth == 0 {
            return "100%"  // Full width
        } else {
            return "\(maxWidth)px"
        }
    }

    /// Get code theme colors based on selected theme
    /// Returns: (lightBackground, darkBackground, lightText, darkText)
    private var codeThemeCSS: (background: String, darkBackground: String, textColor: String, darkTextColor: String) {
        switch codeTheme {
        case "atom-one-dark":
            return ("#282c34", "#282c34", "#abb2bf", "#abb2bf")
        case "github":
            return ("#f6f8fa", "#2d333b", "#24292e", "#c9d1d9")
        case "monokai":
            return ("#272822", "#272822", "#f8f8f2", "#f8f8f2")
        case "vs":
            return ("#ffffff", "#1e1e1e", "#000000", "#d4d4d4")
        case "xcode":
            return ("#ffffff", "#292a30", "#000000", "#ffffff")
        case "dracula":
            return ("#282a36", "#282a36", "#f8f8f2", "#f8f8f2")
        default:
            return ("#f5f5f5", "#2d2d2d", "#333333", "#e5e5e5")
        }
    }

    private func wrapInHTMLTemplate(_ content: String) -> String {
        let themeColors = codeThemeCSS
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <!-- KaTeX for math rendering (bundled locally for offline support) -->
            <link rel="stylesheet" href="katex/katex.min.css">
            <script defer src="katex/katex.min.js"></script>
            <script defer src="katex/auto-render.min.js"></script>
            <style>
                :root {
                    color-scheme: light dark;
                    -webkit-user-select: text;
                    user-select: text;
                    --preview-font-size: \(Int(fontSize))px;
                    --preview-max-width: \(maxWidthCSS);
                    --code-bg: \(themeColors.background);
                    --code-text: \(themeColors.textColor);
                }
                * {
                    -webkit-user-modify: read-only !important;
                }
                body {
                    font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                    font-size: var(--preview-font-size);
                    line-height: 1.7;
                    color: #1a1a1a;
                    max-width: var(--preview-max-width);
                    margin: 0 auto;
                    padding: 24px;
                    background: transparent;
                }
                h1 { font-size: 32px; font-weight: 700; margin: 0 0 16px 0; border-bottom: 1px solid #e5e5e5; padding-bottom: 8px; }
                h2 { font-size: 24px; font-weight: 600; margin: 32px 0 12px 0; }
                h3 { font-size: 20px; font-weight: 600; margin: 24px 0 8px 0; }
                h4 { font-size: 16px; font-weight: 600; margin: 20px 0 8px 0; }
                h5 { font-size: 14px; font-weight: 600; margin: 16px 0 6px 0; }
                h6 { font-size: 13px; font-weight: 600; margin: 16px 0 6px 0; color: #6b6b6b; }
                p { margin: 0 0 16px 0; }
                code {
                    font-family: 'SF Mono', Menlo, monospace;
                    background: var(--code-bg);
                    color: var(--code-text);
                    padding: 2px 6px;
                    border-radius: 4px;
                    font-size: 0.875em;
                }
                pre {
                    background: var(--code-bg);
                    padding: 16px;
                    border-radius: 8px;
                    overflow-x: auto;
                    margin: 0 0 16px 0;
                }
                pre code {
                    background: none;
                    padding: 0;
                    font-size: 0.8125em;
                    line-height: 1.5;
                    color: var(--code-text);
                }
                blockquote {
                    border-left: 4px solid #e5e5e5;
                    margin: 0 0 16px 0;
                    padding: 0 0 0 16px;
                    color: #6b6b6b;
                }
                a { color: #0366d6; text-decoration: none; }
                a:hover { text-decoration: underline; }
                ul, ol { margin: 0 0 16px 0; padding-left: 24px; }
                li { margin-bottom: 4px; }
                /* Nested list spacing */
                ul ul, ul ol, ol ul, ol ol {
                    margin: 4px 0 0 0;
                }
                hr { border: none; border-top: 1px solid #e5e5e5; margin: 24px 0; }
                table { border-collapse: collapse; margin: 0 0 16px 0; width: 100%; }
                th, td { border: 1px solid #e5e5e5; padding: 8px 12px; text-align: left; }
                th { background: #f9f9f9; font-weight: 600; }
                img { max-width: 100%; height: auto; border-radius: 4px; }
                input[type="checkbox"] { margin-right: 8px; pointer-events: none; }
                del { color: #6b6b6b; }
                mark { background: #fff3b0; padding: 1px 4px; border-radius: 2px; }

                /* Footnotes */
                .footnotes { font-size: 14px; color: #6b6b6b; margin-top: 32px; }
                .footnotes ol { padding-left: 20px; }
                .footnotes li { margin-bottom: 8px; }
                sup a { color: #0366d6; text-decoration: none; font-weight: 500; }
                sup a:hover { text-decoration: underline; }

                /* Table of Contents */
                .toc {
                    background: #f9f9f9;
                    border: 1px solid #e5e5e5;
                    border-radius: 6px;
                    padding: 16px 20px;
                    margin: 0 0 24px 0;
                }
                .toc ul { list-style: none; padding-left: 0; margin: 0; }
                .toc ul ul { padding-left: 16px; margin-top: 4px; }
                .toc li { margin-bottom: 4px; }
                .toc a { color: #0366d6; text-decoration: none; }
                .toc a:hover { text-decoration: underline; }

                /* Collapsible sections */
                details {
                    margin: 0 0 16px 0;
                    border: 1px solid #e5e5e5;
                    border-radius: 6px;
                    padding: 8px 12px;
                }
                details[open] { padding-bottom: 12px; }
                summary {
                    cursor: pointer;
                    font-weight: 500;
                    padding: 4px 0;
                    list-style: none;
                }
                summary::-webkit-details-marker { display: none; }
                summary::before {
                    content: "▶";
                    display: inline-block;
                    margin-right: 8px;
                    font-size: 10px;
                    transition: transform 0.2s;
                }
                details[open] summary::before { transform: rotate(90deg); }

                /* Callouts */
                .callout {
                    padding: 12px 16px;
                    border-radius: 6px;
                    margin: 0 0 16px 0;
                    border-left: 4px solid;
                }
                .callout strong {
                    display: block;
                    margin-bottom: 4px;
                }
                .callout p {
                    margin: 4px 0;
                }
                .callout p:last-child {
                    margin-bottom: 0;
                }
                .callout-note { background: #e7f3ff; border-color: #0969da; }
                .callout-tip { background: #d4edda; border-color: #28a745; }
                .callout-warning { background: #fff8e6; border-color: #d29922; }
                .callout-important { background: #f3e8ff; border-color: #8957e5; }
                .callout-caution { background: #ffe7e7; border-color: #d73a49; }

                @media (prefers-color-scheme: dark) {
                    :root {
                        --code-bg: \(themeColors.darkBackground);
                        --code-text: \(themeColors.darkTextColor);
                    }
                    body { color: #e5e5e5; }
                    h1 { border-bottom-color: #3d3d3d; }
                    h6 { color: #8e8e93; }
                    blockquote { border-left-color: #3d3d3d; color: #8e8e93; }
                    a { color: #58a6ff; }
                    sup a { color: #58a6ff; }
                    hr { border-top-color: #3d3d3d; }
                    th, td { border-color: #3d3d3d; }
                    th { background: #2d2d2d; }
                    mark { background: #5c4d00; color: #fff; }
                    details { border-color: #3d3d3d; }
                    .footnotes { color: #8e8e93; }
                    .toc { background: #2d2d2d; border-color: #3d3d3d; }
                    .toc a { color: #58a6ff; }
                    .callout-note { background: #1c3a5e; }
                    .callout-tip { background: #1e3a2a; }
                    .callout-warning { background: #3d3420; }
                    .callout-important { background: #2d2640; }
                    .callout-caution { background: #3d2020; }
                }

                /* Math */
                .math-display {
                    overflow-x: auto;
                    margin: 16px 0;
                    text-align: center;
                }
                .math-inline {
                    padding: 0 2px;
                }

                /* Definition lists */
                dl {
                    margin: 0 0 16px 0;
                }
                dt {
                    font-weight: 600;
                    margin-top: 12px;
                }
                dt:first-child {
                    margin-top: 0;
                }
                dd {
                    margin: 4px 0 8px 24px;
                    color: #4a4a4a;
                }
                @media (prefers-color-scheme: dark) {
                    dd { color: #a0a0a0; }
                }
            </style>
        </head>
        <body>
            \(content)
            <script>
                document.addEventListener("DOMContentLoaded", function() {
                    if (typeof renderMathInElement !== 'undefined') {
                        renderMathInElement(document.body, {
                            delimiters: [
                                {left: '$$', right: '$$', display: true}
                            ],
                            throwOnError: false
                        });
                    }
                });
            </script>
        </body>
        </html>
        """
    }
}

// MARK: - WebView Wrapper

struct MarkdownWebView: NSViewRepresentable {
    let html: String
    let baseURL: URL?

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.setValue(false, forKey: "drawsBackground")

        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        // Inject script to disable all editing before loading
        let htmlWithNoEdit = html.replacingOccurrences(
            of: "<body>",
            with: "<body contenteditable=\"false\" style=\"-webkit-user-modify: read-only;\">"
        )
        webView.loadHTMLString(htmlWithNoEdit, baseURL: baseURL)
    }
}

// MARK: - Preview Empty State

struct PreviewEmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "eye.slash")
                .font(.system(size: 40))
                .foregroundColor(.secondary.opacity(0.4))

            Text("No Preview")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Open or create a document to see the preview")
                .font(.subheadline)
                .foregroundColor(.secondary.opacity(0.7))
                .multilineTextAlignment(.center)

            // Shortcut hint
            Text("⌘\\ to toggle preview")
                .font(.system(size: 11))
                .foregroundColor(.secondary.opacity(0.5))
                .padding(.top, 4)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview Unsupported State

struct PreviewUnsupportedView: View {
    let fileExtension: String
    
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "doc.text")
                .font(.system(size: 40))
                .foregroundColor(.secondary.opacity(0.4))
            
            Text("Preview Not Available")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Preview is only available for Markdown files")
                .font(.subheadline)
                .foregroundColor(.secondary.opacity(0.7))
                .multilineTextAlignment(.center)
            
            if !fileExtension.isEmpty {
                Text("Current file type: .\(fileExtension)")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary.opacity(0.5))
                    .padding(.top, 4)
            }
            
            Text("⌘\\ to hide preview")
                .font(.system(size: 11))
                .foregroundColor(.secondary.opacity(0.5))
                .padding(.top, 4)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
