//
//  GitHistoryView.swift
//  tibok
//
//  Git commit history browser
//

import SwiftUI

struct GitHistoryView: View {
    @EnvironmentObject var appState: AppState
    let repoURL: URL
    let onDismiss: () -> Void

    @State private var commits: [GitCommit] = []
    @State private var selectedCommit: GitCommit?
    @State private var isLoading = true

    var body: some View {
        NavigationSplitView {
            // Commit list
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Commit History")
                        .font(.headline)
                    Spacer()
                    Button("Close") {
                        onDismiss()
                    }
                    .keyboardShortcut(.cancelAction)
                }
                .padding()
                .background(Color(NSColor.windowBackgroundColor))

                Divider()

                if isLoading {
                    VStack {
                        Spacer()
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Loading commits...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                        Spacer()
                    }
                } else if commits.isEmpty {
                    VStack {
                        Spacer()
                        Image(systemName: "clock")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary.opacity(0.4))
                        Text("No commits")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                        Spacer()
                    }
                } else {
                    List(commits, selection: $selectedCommit) { commit in
                        CommitRowView(commit: commit)
                            .tag(commit)
                    }
                }
            }
            .frame(minWidth: 300)
        } detail: {
            // Commit detail
            if let commit = selectedCommit {
                GitCommitDetailView(commit: commit, repoURL: repoURL)
            } else {
                VStack {
                    Spacer()
                    Image(systemName: "arrow.left")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary.opacity(0.4))
                    Text("Select a commit")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                    Spacer()
                }
            }
        }
        .frame(width: 900, height: 600)
        .onAppear {
            loadCommits()
        }
    }

    private func loadCommits() {
        Task {
            let commitList = LibGit2Service.shared.getCommitLog(for: repoURL, limit: 100)

            await MainActor.run {
                if commitList.isEmpty {
                    print("GitHistoryView: No commits found")
                }
                commits = commitList
                isLoading = false
                if !commits.isEmpty {
                    selectedCommit = commits[0]
                }
            }
        }
    }
}

// MARK: - Commit Row View

struct CommitRowView: View {
    let commit: GitCommit

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(commit.message)
                .font(.system(size: 12, weight: .medium))
                .lineLimit(2)

            HStack(spacing: 8) {
                Text(commit.author)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)

                Text("•")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)

                Text(commit.shortHash)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.purple)

                Text("•")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)

                Text(relativeTimeString(from: commit.date))
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func relativeTimeString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Commit Detail View

struct GitCommitDetailView: View {
    let commit: GitCommit
    let repoURL: URL

    @State private var files: [String] = []
    @State private var diffContent: String = ""
    @State private var isLoading = true

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text(commit.message)
                    .font(.headline)

                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "person")
                            .font(.system(size: 10))
                        Text(commit.author)
                            .font(.system(size: 11))
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "number")
                            .font(.system(size: 10))
                        Text(commit.shortHash)
                            .font(.system(size: 11, design: .monospaced))
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 10))
                        Text(commit.date, style: .date)
                            .font(.system(size: 11))
                    }

                    if !files.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "doc.text")
                                .font(.system(size: 10))
                            Text("\(files.count) file\(files.count == 1 ? "" : "s")")
                                .font(.system(size: 11))
                        }
                    }
                }
                .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
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
        .onAppear {
            loadCommitDetail()
        }
    }

    private func loadCommitDetail() {
        Task {
            let fileList = LibGit2Service.shared.getCommitFiles(hash: commit.hash, in: repoURL)
            let diff = LibGit2Service.shared.getCommitDiff(hash: commit.hash, in: repoURL)

            await MainActor.run {
                files = fileList
                diffContent = diff ?? ""
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
                attributedLine.foregroundColor = .green
                attributedLine.backgroundColor = Color.green.opacity(0.1)
            } else if line.hasPrefix("-") && !line.hasPrefix("---") {
                attributedLine.foregroundColor = .red
                attributedLine.backgroundColor = Color.red.opacity(0.1)
            } else if line.hasPrefix("@@") {
                attributedLine.foregroundColor = .purple
                attributedLine.font = .system(.body, design: .monospaced).bold()
            } else if line.hasPrefix("commit ") || line.hasPrefix("Author: ") || line.hasPrefix("Date: ") || line.hasPrefix("diff --git") || line.hasPrefix("index ") || line.hasPrefix("---") || line.hasPrefix("+++") {
                attributedLine.foregroundColor = Color(NSColor.secondaryLabelColor)
            } else {
                attributedLine.foregroundColor = Color(NSColor.labelColor)
            }

            result.append(attributedLine)

            if index < lines.count - 1 {
                result.append(AttributedString("\n"))
            }
        }

        return result
    }
}
