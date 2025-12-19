import Foundation
import AppKit
import WebKit
import UniformTypeIdentifiers

@MainActor
class ExportService {
    static let shared = ExportService()

    // State for WebView export
    private var exportWebView: WKWebView?
    private var exportDelegate: WebViewExportDelegate?
    private var pendingPDFURL: URL?

    // State for print
    private var printWebView: WKWebView?
    private var printDelegate: WebViewPrintDelegate?

    private init() {}

    // MARK: - PDF Export

    func exportAsPDF(document: Document, showToast: @escaping (String, String?, TimeInterval) -> Void) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType.pdf]
        panel.nameFieldStringValue = "\(document.title).pdf"

        guard panel.runModal() == .OK, let url = panel.url else { return }

        // Check for relative images and warn
        let hasRelativeImages = document.content.contains("](./assets/") ||
                               document.content.contains("](assets/")
        if hasRelativeImages {
            showToast("Note: Relative image paths may not work in PDF",
                     "photo.badge.exclamationmark", 3.0)
        }

        showToast("Generating PDF...", "doc.text", 1.0)

        // Render markdown to HTML with print styles
        let html = wrapHTMLForPrint(MarkdownRenderer.render(document.content), title: document.title)

        // Create and retain WebView and delegate
        let webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 612, height: 792))
        let delegate = WebViewExportDelegate { [weak self] in
            self?.finishPDFExport(document: document, showToast: showToast)
        }
        self.exportWebView = webView
        self.exportDelegate = delegate
        self.pendingPDFURL = url

        webView.navigationDelegate = delegate
        webView.loadHTMLString(html, baseURL: nil)
    }

    private func finishPDFExport(document: Document, showToast: @escaping (String, String?, TimeInterval) -> Void) {
        guard let webView = exportWebView, let url = pendingPDFURL else { return }

        // Use print operation for proper multi-page PDF
        let printInfo = NSPrintInfo()
        printInfo.paperSize = NSSize(width: 612, height: 792) // Letter
        printInfo.topMargin = 54    // 0.75 inch
        printInfo.bottomMargin = 54
        printInfo.leftMargin = 54
        printInfo.rightMargin = 54
        printInfo.horizontalPagination = .fit
        printInfo.verticalPagination = .automatic
        printInfo.isHorizontallyCentered = false
        printInfo.isVerticallyCentered = false
        printInfo.jobDisposition = .save
        printInfo.dictionary()[NSPrintInfo.AttributeKey.jobSavingURL] = url

        let printOp = webView.printOperation(with: printInfo)
        printOp.showsPrintPanel = false
        printOp.showsProgressPanel = false

        printOp.runModal(for: NSApp.mainWindow ?? NSWindow(), delegate: nil, didRun: nil, contextInfo: nil)

        showToast("PDF exported successfully", "checkmark.circle.fill", 2.0)

        // Trigger document.export webhooks
        let (frontmatter, _) = Frontmatter.parse(from: document.content)
        Task {
            await WebhookService.shared.triggerDocumentExport(
                filename: url.lastPathComponent,
                title: frontmatter?.title,
                path: url.path,
                exportFormat: "pdf"
            )
        }

        // Clean up after print
        exportWebView = nil
        exportDelegate = nil
        pendingPDFURL = nil
    }

    // MARK: - HTML Export

    func exportAsHTML(document: Document, showToast: @escaping (String, String?, TimeInterval) -> Void) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType.html]
        panel.nameFieldStringValue = "\(document.title).html"

        guard panel.runModal() == .OK, let url = panel.url else { return }

        let html = wrapHTMLForExport(MarkdownRenderer.render(document.content), title: document.title)

        do {
            try html.write(to: url, atomically: true, encoding: .utf8)

            // Context-aware success notification
            let hasRelativeImages = document.content.contains("](./assets/") ||
                                   document.content.contains("](assets/")
            if hasRelativeImages {
                showToast("Images use relative paths - keep assets folder",
                         "photo", 3.0)
            } else {
                showToast("HTML exported successfully",
                         "checkmark.circle.fill", 2.0)
            }

            // Trigger document.export webhooks
            let (frontmatter, _) = Frontmatter.parse(from: document.content)
            Task {
                await WebhookService.shared.triggerDocumentExport(
                    filename: url.lastPathComponent,
                    title: frontmatter?.title,
                    path: url.path,
                    exportFormat: "html"
                )
            }
        } catch {
            showToast("Failed to export HTML", "exclamationmark.triangle.fill", 2.0)
        }
    }

    // MARK: - RTF Export

    func exportAsRTF(document: Document, showToast: @escaping (String, String?, TimeInterval) -> Void) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType.rtf]
        panel.nameFieldStringValue = "\(document.title).rtf"

        guard panel.runModal() == .OK, let url = panel.url else { return }

        // Convert HTML to attributed string, then to RTF
        let html = wrapHTMLForExport(MarkdownRenderer.render(document.content), title: document.title)

        guard let htmlData = html.data(using: .utf8),
              let attributedString = try? NSAttributedString(
                  data: htmlData,
                  options: [
                      .documentType: NSAttributedString.DocumentType.html,
                      .characterEncoding: String.Encoding.utf8.rawValue
                  ],
                  documentAttributes: nil
              ) else {
            showToast("Failed to export RTF", "exclamationmark.triangle.fill", 2.0)
            return
        }

        // Convert to RTF
        guard let rtfData = try? attributedString.data(
            from: NSRange(location: 0, length: attributedString.length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
        ) else {
            showToast("Failed to export RTF", "exclamationmark.triangle.fill", 2.0)
            return
        }

        do {
            try rtfData.write(to: url)

            // Trigger document.export webhooks
            let (frontmatter, _) = Frontmatter.parse(from: document.content)
            Task {
                await WebhookService.shared.triggerDocumentExport(
                    filename: url.lastPathComponent,
                    title: frontmatter?.title,
                    path: url.path,
                    exportFormat: "rtf"
                )
            }
        } catch {
            showToast("Failed to export RTF", "exclamationmark.triangle.fill", 2.0)
        }
    }

    // MARK: - Plain Text Export

    func exportAsPlainText(document: Document, showToast: @escaping (String, String?, TimeInterval) -> Void) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType.plainText]
        panel.nameFieldStringValue = "\(document.title).txt"

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            try document.content.write(to: url, atomically: true, encoding: .utf8)

            // Trigger document.export webhooks
            let (frontmatter, _) = Frontmatter.parse(from: document.content)
            Task {
                await WebhookService.shared.triggerDocumentExport(
                    filename: url.lastPathComponent,
                    title: frontmatter?.title,
                    path: url.path,
                    exportFormat: "txt"
                )
            }
        } catch {
            showToast("Failed to export text", "exclamationmark.triangle.fill", 2.0)
        }
    }

    // MARK: - WordPress Export

    func exportToWordPress(document: Document, showToast: @escaping (String, String?, TimeInterval) -> Void) {
        // Get WordPress email address from settings
        let wordpressEmail = UserDefaults.standard.string(forKey: "plugin.wordpress.emailAddress") ?? ""

        guard !wordpressEmail.isEmpty else {
            showToast("WordPress not configured. Go to Settings > WordPress.", "exclamationmark.triangle", 2.0)
            return
        }

        // Parse frontmatter for title, categories, and tags
        let (frontmatter, body) = Frontmatter.parse(from: document.content)
        let title = frontmatter?.title ?? document.title

        // Convert markdown to HTML (WordPress supports HTML in email)
        let htmlContent = MarkdownRenderer.render(body)

        // Build email body with WordPress formatting
        var emailBody = htmlContent

        // Add status if draft (WordPress syntax: [status draft])
        if frontmatter?.draft == true {
            emailBody = "[status draft]\n\n\(emailBody)"
        }

        // Add excerpt if present (WordPress syntax: [excerpt text])
        if let description = frontmatter?.description, !description.isEmpty {
            emailBody = "[excerpt \(description)]\n\n\(emailBody)"
        }

        // Add categories if present (WordPress syntax: [category CategoryName])
        if let categories = frontmatter?.categories, !categories.isEmpty {
            let categorySyntax = categories.map { "[category \($0)]" }.joined(separator: " ")
            emailBody = "\(categorySyntax)\n\n\(emailBody)"
        }

        // Add tags if present (WordPress syntax: [tags tag1, tag2, tag3])
        if let tags = frontmatter?.tags, !tags.isEmpty {
            let tagSyntax = "[tags \(tags.joined(separator: ", "))]"
            emailBody = "\(tagSyntax)\n\n\(emailBody)"
        }

        // Check content length - mailto URLs have practical limits of ~2000-8000 chars
        let estimatedEncodedLength = emailBody.count * 3

        if estimatedEncodedLength > 7000 {
            // Content too long - save to temp file
            let tempDir = FileManager.default.temporaryDirectory
            let tempFile = tempDir.appendingPathComponent("\(title).html")

            do {
                try emailBody.write(to: tempFile, atomically: true, encoding: .utf8)
                NSWorkspace.shared.activateFileViewerSelecting([tempFile])
                showToast("Content too long for email. HTML file saved - copy content manually", "exclamationmark.triangle.fill", 5.0)

                // Copy to clipboard
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(emailBody, forType: .string)

                // Show instructions
                DispatchQueue.main.async {
                    let alert = NSAlert()
                    alert.messageText = "Document Too Long for Email"
                    alert.informativeText = """
                    Your document (\(emailBody.count) characters) exceeds email URL limits.

                    Options:
                    1. HTML file opened in Finder - manually attach to email
                    2. Content copied to clipboard - paste into email
                    3. Consider using WordPress API publishing instead

                    Send to: \(wordpressEmail)
                    Subject: \(title)
                    """
                    alert.alertStyle = .warning
                    alert.addButton(withTitle: "OK")
                    alert.runModal()
                }
            } catch {
                showToast("Failed to save content: \(error.localizedDescription)", "exclamationmark.triangle.fill", 3.0)
            }
            return
        }

        // URL encode the subject and body
        guard let encodedSubject = title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let encodedBody = emailBody.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            showToast("Failed to encode email", "exclamationmark.triangle.fill", 2.0)
            return
        }

        // Create mailto URL
        let mailtoURL = "mailto:\(wordpressEmail)?subject=\(encodedSubject)&body=\(encodedBody)"

        // Verify URL length
        if mailtoURL.count > 8000 {
            showToast("Email content too long - try shorter document", "exclamationmark.triangle.fill", 3.0)
            return
        }

        // Open default email client
        if let url = URL(string: mailtoURL) {
            NSWorkspace.shared.open(url)
            showToast("Opening email client...", "envelope.fill", 1.5)

            // Trigger document.export webhooks
            Task {
                await WebhookService.shared.triggerDocumentExport(
                    filename: document.fileURL?.lastPathComponent ?? "\(title).md",
                    title: frontmatter?.title,
                    path: document.fileURL?.path ?? "",
                    exportFormat: "wordpress"
                )
            }
        } else {
            showToast("Failed to open email client", "exclamationmark.triangle.fill", 2.0)
        }
    }

    // MARK: - Copy as Markdown

    func copyAsMarkdown(document: Document, showToast: @escaping (String, String?, TimeInterval) -> Void) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(document.content, forType: .string)

        // Context-aware notification
        let hasRelativeImages = document.content.contains("](./assets/") ||
                               document.content.contains("](assets/")

        if hasRelativeImages {
            showToast("Copied (images not included)", "doc.on.clipboard", 2.5)
        } else {
            showToast("Copied to clipboard", "doc.on.clipboard.fill", 1.5)
        }
    }

    // MARK: - Print

    func printDocument(_ document: Document) {
        guard !document.isEmpty else { return }

        // Render markdown to HTML for printing
        let html = wrapHTMLForPrint(MarkdownRenderer.render(document.content), title: document.title)

        // Create WebView for rendering
        let webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 612, height: 792))
        let delegate = WebViewPrintDelegate { [weak self] in
            self?.showPrintDialog()
        }
        self.printWebView = webView
        self.printDelegate = delegate

        webView.navigationDelegate = delegate
        webView.loadHTMLString(html, baseURL: Bundle.main.resourceURL)
    }

    private func showPrintDialog() {
        guard let webView = printWebView else { return }

        let printInfo = NSPrintInfo.shared
        printInfo.paperSize = NSSize(width: 612, height: 792)
        printInfo.topMargin = 54
        printInfo.bottomMargin = 54
        printInfo.leftMargin = 54
        printInfo.rightMargin = 54
        printInfo.horizontalPagination = .fit
        printInfo.verticalPagination = .automatic

        let printOp = webView.printOperation(with: printInfo)
        printOp.showsPrintPanel = true
        printOp.showsProgressPanel = true

        printOp.runModal(for: NSApp.mainWindow ?? NSWindow(), delegate: nil, didRun: nil, contextInfo: nil)

        // Clean up
        printWebView = nil
        printDelegate = nil
    }

    // MARK: - HTML Wrappers

    private func wrapHTMLForPrint(_ content: String, title: String) -> String {
        """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <title>\(title)</title>
            <style>
                @page {
                    size: letter;
                    margin: 0.75in 1in;
                }
                body {
                    font-family: 'Georgia', 'Times New Roman', serif;
                    font-size: 11pt;
                    line-height: 1.6;
                    color: #1a1a1a;
                    margin: 0;
                    padding: 0;
                }
                /* Headings */
                h1 {
                    font-family: -apple-system, BlinkMacSystemFont, 'Helvetica Neue', sans-serif;
                    font-size: 22pt;
                    font-weight: 600;
                    margin: 0 0 14pt 0;
                    padding-bottom: 6pt;
                    border-bottom: 1pt solid #e0e0e0;
                    page-break-after: avoid;
                }
                h2 {
                    font-family: -apple-system, BlinkMacSystemFont, 'Helvetica Neue', sans-serif;
                    font-size: 16pt;
                    font-weight: 600;
                    margin: 18pt 0 10pt 0;
                    page-break-after: avoid;
                }
                h3 {
                    font-family: -apple-system, BlinkMacSystemFont, 'Helvetica Neue', sans-serif;
                    font-size: 13pt;
                    font-weight: 600;
                    margin: 14pt 0 8pt 0;
                    page-break-after: avoid;
                }
                h4, h5, h6 {
                    font-family: -apple-system, BlinkMacSystemFont, 'Helvetica Neue', sans-serif;
                    font-size: 11pt;
                    font-weight: 600;
                    margin: 12pt 0 6pt 0;
                    page-break-after: avoid;
                }
                h5, h6 { color: #4a4a4a; }

                /* Paragraphs */
                p {
                    margin: 0 0 10pt 0;
                    orphans: 3;
                    widows: 3;
                    text-align: justify;
                    hyphens: auto;
                }

                /* Code */
                code {
                    font-family: 'SF Mono', 'Menlo', 'Consolas', monospace;
                    background: #f4f4f4;
                    padding: 1pt 4pt;
                    border-radius: 2pt;
                    font-size: 9pt;
                    color: #333;
                }
                pre {
                    background: #f8f8f8;
                    padding: 10pt;
                    border-radius: 4pt;
                    border: 0.5pt solid #e0e0e0;
                    overflow-x: auto;
                    page-break-inside: avoid;
                    margin: 0 0 10pt 0;
                }
                pre code {
                    background: none;
                    padding: 0;
                    font-size: 8.5pt;
                    line-height: 1.4;
                    border: none;
                }

                /* Blockquotes */
                blockquote {
                    border-left: 3pt solid #d0d0d0;
                    margin: 0 0 10pt 0;
                    padding: 6pt 0 6pt 12pt;
                    color: #555;
                    font-style: italic;
                    page-break-inside: avoid;
                }
                blockquote p { margin-bottom: 6pt; }
                blockquote p:last-child { margin-bottom: 0; }

                /* Links */
                a {
                    color: #0055aa;
                    text-decoration: none;
                }

                /* Lists */
                ul, ol {
                    margin: 0 0 10pt 0;
                    padding-left: 20pt;
                }
                li {
                    margin-bottom: 4pt;
                }
                li > ul, li > ol {
                    margin-top: 4pt;
                    margin-bottom: 0;
                }

                /* Task lists */
                input[type="checkbox"] {
                    margin-right: 6pt;
                }

                /* Horizontal rule */
                hr {
                    border: none;
                    border-top: 0.5pt solid #ccc;
                    margin: 16pt 0;
                }

                /* Tables */
                table {
                    border-collapse: collapse;
                    margin: 0 0 10pt 0;
                    page-break-inside: avoid;
                    width: 100%;
                    font-size: 10pt;
                }
                th, td {
                    border: 0.5pt solid #ccc;
                    padding: 6pt 10pt;
                    text-align: left;
                }
                th {
                    background: #f4f4f4;
                    font-weight: 600;
                }

                /* Images */
                img {
                    max-width: 100%;
                    height: auto;
                    page-break-inside: avoid;
                }

                /* Callouts */
                .callout {
                    padding: 10pt 12pt;
                    border-radius: 4pt;
                    margin: 0 0 10pt 0;
                    border-left: 4pt solid;
                    page-break-inside: avoid;
                }
                .callout strong { display: block; margin-bottom: 4pt; }
                .callout p { margin: 4pt 0; }
                .callout p:last-child { margin-bottom: 0; }
                .callout-note { background: #e8f4fd; border-color: #0969da; }
                .callout-tip { background: #e6f6e6; border-color: #1a7f37; }
                .callout-warning { background: #fff8e6; border-color: #d29922; }
                .callout-important { background: #f6e8ff; border-color: #8250df; }
                .callout-caution { background: #ffe8e8; border-color: #cf222e; }

                /* Footnotes */
                .footnotes {
                    margin-top: 24pt;
                    padding-top: 12pt;
                    border-top: 0.5pt solid #ccc;
                    font-size: 9pt;
                    color: #555;
                }
                .footnotes ol { padding-left: 16pt; }
                .footnotes li { margin-bottom: 6pt; }
                sup a {
                    color: #0055aa;
                    font-weight: 500;
                }

                /* Table of Contents */
                .toc {
                    background: #f8f8f8;
                    border: 0.5pt solid #e0e0e0;
                    border-radius: 4pt;
                    padding: 12pt 16pt;
                    margin: 0 0 16pt 0;
                    page-break-inside: avoid;
                }
                .toc ul { list-style: none; padding-left: 0; margin: 0; }
                .toc ul ul { padding-left: 14pt; margin-top: 4pt; }
                .toc li { margin-bottom: 4pt; }
                .toc a { color: #333; }

                /* Definition lists */
                dl { margin: 0 0 10pt 0; }
                dt { font-weight: 600; margin-top: 8pt; }
                dt:first-child { margin-top: 0; }
                dd { margin: 2pt 0 6pt 20pt; color: #444; }

                /* Collapsible sections (print expanded) */
                details { margin: 0 0 10pt 0; }
                summary { font-weight: 600; cursor: default; }

                /* Strikethrough and mark */
                del { color: #666; }
                mark { background: #fff3b0; padding: 1pt 2pt; }

                /* Print-specific */
                @media print {
                    a[href]:after { content: ""; }  /* Don't show URLs after links */
                }
            </style>
        </head>
        <body>
            \(content)
        </body>
        </html>
        """
    }

    private func wrapHTMLForExport(_ content: String, title: String) -> String {
        """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <title>\(title)</title>
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                    font-size: 14px;
                    line-height: 1.6;
                    color: #333;
                    max-width: 700px;
                    margin: 40px auto;
                    padding: 0 20px;
                }
                h1 { font-size: 28px; font-weight: 700; margin: 0 0 16px 0; }
                h2 { font-size: 22px; font-weight: 600; margin: 32px 0 12px 0; }
                h3 { font-size: 18px; font-weight: 600; margin: 24px 0 8px 0; }
                p { margin: 0 0 16px 0; }
                code {
                    font-family: 'SF Mono', Menlo, monospace;
                    background: #f5f5f5;
                    padding: 2px 6px;
                    border-radius: 4px;
                    font-size: 13px;
                }
                pre {
                    background: #f5f5f5;
                    padding: 16px;
                    border-radius: 8px;
                    overflow-x: auto;
                }
                pre code { background: none; padding: 0; }
                blockquote {
                    border-left: 4px solid #ddd;
                    margin: 0 0 16px 0;
                    padding: 0 0 0 16px;
                    color: #666;
                }
                a { color: #0066cc; }
                ul, ol { margin: 0 0 16px 0; padding-left: 24px; }
                hr { border: none; border-top: 1px solid #ddd; margin: 24px 0; }
                table { border-collapse: collapse; margin: 0 0 16px 0; }
                th, td { border: 1px solid #ddd; padding: 8px 12px; }
                th { background: #f9f9f9; }
                img { max-width: 100%; }
            </style>
        </head>
        <body>
            \(content)
        </body>
        </html>
        """
    }
}

// MARK: - WebView Export Delegate

private class WebViewExportDelegate: NSObject, WKNavigationDelegate {
    private let onFinish: () -> Void

    init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Small delay to ensure rendering is complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.onFinish()
        }
    }
}

// MARK: - WebView Print Delegate

private class WebViewPrintDelegate: NSObject, WKNavigationDelegate {
    private let onFinish: () -> Void

    init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Small delay to ensure rendering is complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.onFinish()
        }
    }
}
