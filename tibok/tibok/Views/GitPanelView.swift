//
//  GitPanelView.swift
//  tibok
//
//  Git changes panel showing staged and unstaged files with commit functionality.
//

import SwiftUI

struct GitPanelView: View {
    @EnvironmentObject var appState: AppState
    @State private var commitMessage = ""
    @State private var showCommitSheet = false
    @State private var commitError: String?
    @State private var showError = false
    @AppStorage("sidebar.showGit") private var persistShowGit = true

    var body: some View {
        Section {
            if persistShowGit {
                // Staged changes section
                if !appState.stagedFiles.isEmpty {
                    DisclosureGroup {
                        ForEach(appState.stagedFiles, id: \.id) { file in
                            GitFileRow(file: file, isStaged: true)
                        }
                    } label: {
                        HStack {
                            Text("Staged")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.green)
                            Spacer()
                            Text("\(appState.stagedFiles.count)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // Unstaged changes section
                if !appState.unstagedFiles.isEmpty {
                    DisclosureGroup {
                        ForEach(appState.unstagedFiles, id: \.id) { file in
                            GitFileRow(file: file, isStaged: false)
                        }
                    } label: {
                        HStack {
                            Text("Changes")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.blue)
                            Spacer()
                            Text("\(appState.unstagedFiles.count)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // No changes message
                if appState.stagedFiles.isEmpty && appState.unstagedFiles.isEmpty {
                    Text("No changes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 4)
                }

                // Action buttons
                HStack(spacing: 8) {
                    // Stage all button
                    if !appState.unstagedFiles.isEmpty {
                        Button {
                            appState.stageAll()
                        } label: {
                            Image(systemName: "plus.circle")
                                .font(.system(size: 12))
                        }
                        .buttonStyle(.plain)
                        .help("Stage All")
                    }

                    // Unstage all button
                    if !appState.stagedFiles.isEmpty {
                        Button {
                            appState.unstageAll()
                        } label: {
                            Image(systemName: "minus.circle")
                                .font(.system(size: 12))
                        }
                        .buttonStyle(.plain)
                        .help("Unstage All")
                    }

                    Spacer()

                    // Commit button
                    if !appState.stagedFiles.isEmpty {
                        Button {
                            showCommitSheet = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle")
                                    .font(.system(size: 11))
                                Text("Commit")
                                    .font(.system(size: 11))
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }
                .padding(.top, 4)
            }
        } header: {
            CollapsibleSectionHeader(
                title: "Git",
                isExpanded: $persistShowGit
            )
        }
        .sheet(isPresented: $showCommitSheet) {
            GitCommitSheet(
                message: $commitMessage,
                stagedCount: appState.stagedFiles.count,
                onCommit: {
                    let result = appState.commitChanges(message: commitMessage)
                    if result.success {
                        commitMessage = ""
                        showCommitSheet = false
                    } else {
                        commitError = result.error
                        showError = true
                    }
                },
                onCancel: {
                    showCommitSheet = false
                }
            )
        }
        .alert("Commit Failed", isPresented: $showError) {
            Button("OK") {
                showError = false
            }
        } message: {
            Text(commitError ?? "Unknown error")
        }
    }
}

// MARK: - Git File Row

struct GitFileRow: View {
    @EnvironmentObject var appState: AppState
    let file: GitChangedFile
    let isStaged: Bool

    var body: some View {
        HStack(spacing: 4) {
            // Status indicator
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)

            // Filename
            Text(file.filename)
                .font(.system(size: 11))
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer()

            // Action buttons
            if isStaged {
                Button {
                    appState.unstageFile(file.url)
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Unstage")
            } else {
                Button {
                    appState.stageFile(file.url)
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Stage")

                if file.status != .untracked {
                    Button {
                        appState.discardChanges(file.url)
                    } label: {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Discard Changes")
                }
            }
        }
        .padding(.vertical, 1)
        .contentShape(Rectangle())
        .contextMenu {
            Button("Open File") {
                appState.loadDocument(from: file.url)
            }
            Divider()
            if isStaged {
                Button("Unstage") {
                    appState.unstageFile(file.url)
                }
            } else {
                Button("Stage") {
                    appState.stageFile(file.url)
                }
                if file.status != .untracked {
                    Button("Discard Changes", role: .destructive) {
                        appState.discardChanges(file.url)
                    }
                }
            }
            Divider()
            Button("Reveal in Finder") {
                appState.revealInFinder(file.url)
            }
        }
    }

    private var statusColor: Color {
        switch file.status {
        case .modified:
            return .blue
        case .added, .staged:
            return .green
        case .untracked:
            return .yellow
        case .unmerged:
            return .red
        case .deleted, .stagedDeleted:
            return .gray
        default:
            return .clear
        }
    }
}

// MARK: - Git Commit Sheet

struct GitCommitSheet: View {
    @Binding var message: String
    let stagedCount: Int
    let onCommit: () -> Void
    let onCancel: () -> Void
    @FocusState private var isMessageFocused: Bool

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Commit Changes")
                    .font(.headline)
                Spacer()
            }

            // Staged count
            HStack {
                Text("\(stagedCount) file\(stagedCount == 1 ? "" : "s") staged")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }

            // Message input
            VStack(alignment: .leading, spacing: 4) {
                Text("Commit message")
                    .font(.caption)
                    .foregroundColor(.secondary)

                TextEditor(text: $message)
                    .font(.system(size: 13))
                    .frame(height: 80)
                    .scrollContentBackground(.hidden)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                    )
                    .focused($isMessageFocused)
            }

            // Buttons
            HStack {
                Button("Cancel") {
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Commit") {
                    onCommit()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
        .frame(width: 400)
        .onAppear {
            isMessageFocused = true
        }
    }
}
