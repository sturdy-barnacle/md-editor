//
//  GitDiffView.swift
//  tibok
//
//  Git diff viewer with syntax highlighting
//

import SwiftUI

struct GitDiffView: View {
    @EnvironmentObject var appState: AppState
    let fileURL: URL
    let repoURL: URL
    let isStaged: Bool
    let onDismiss: () -> Void

    @State private var diffContent: String = ""
    @State private var isLoading = true

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(fileURL.lastPathComponent)
                        .font(.headline)
                    Text(isStaged ? "Staged Changes" : "Unstaged Changes")
                        .font(.caption)
                        .foregroundColor(isStaged ? .green : .blue)
                }

                Spacer()

                Button("Close") {
                    onDismiss()
                }
                .keyboardShortcut(.cancelAction)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            // Diff content
            if isLoading {
                VStack {
                    Spacer()
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading diff...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                    Spacer()
                }
            } else if diffContent.isEmpty {
                VStack {
                    Spacer()
                    Image(systemName: "doc.text")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary.opacity(0.4))
                    Text("No changes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                    Spacer()
                }
            } else {
                ScrollView {
                    Text(highlightedDiff)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
                .background(Color(NSColor.textBackgroundColor))
            }
        }
        .frame(width: 700, height: 500)
        .onAppear {
            loadDiff()
        }
    }

    private func loadDiff() {
        Task {
            let diff = LibGit2Service.shared.getDiff(for: fileURL, in: repoURL, staged: isStaged)

            await MainActor.run {
                if let diff = diff {
                    diffContent = diff
                } else {
                    print("GitDiffView: Failed to load diff for \(fileURL.lastPathComponent)")
                    diffContent = ""
                }
                isLoading = false
            }
        }
    }

    private var highlightedDiff: AttributedString {
        var result = AttributedString()
        let lines = diffContent.components(separatedBy: .newlines)

        for (index, line) in lines.enumerated() {
            var attributedLine = AttributedString(line)

            // Color based on line prefix
            if line.hasPrefix("+") && !line.hasPrefix("+++") {
                // Addition - green
                attributedLine.foregroundColor = .green
                attributedLine.backgroundColor = Color.green.opacity(0.1)
            } else if line.hasPrefix("-") && !line.hasPrefix("---") {
                // Deletion - red
                attributedLine.foregroundColor = .red
                attributedLine.backgroundColor = Color.red.opacity(0.1)
            } else if line.hasPrefix("@@") {
                // Hunk header - purple
                attributedLine.foregroundColor = .purple
                attributedLine.font = .system(.body, design: .monospaced).bold()
            } else if line.hasPrefix("diff --git") || line.hasPrefix("index ") || line.hasPrefix("---") || line.hasPrefix("+++") {
                // File header - secondary
                attributedLine.foregroundColor = Color(NSColor.secondaryLabelColor)
            } else {
                // Context line - default
                attributedLine.foregroundColor = Color(NSColor.labelColor)
            }

            result.append(attributedLine)

            // Add newline except for last line
            if index < lines.count - 1 {
                result.append(AttributedString("\n"))
            }
        }

        return result
    }
}
