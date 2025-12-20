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
    @State private var sheetMessage = ""  // Separate state for sheet to isolate bindings
    @State private var showCommitSheet = false
    @State private var commitError: String?
    @State private var showError = false
    @State private var committingStagedCount = 0
    @AppStorage("sidebar.showGit") private var persistShowGit = true

    let uiState = UIStateService.shared

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
                        .buttonStyle(.animatedIcon)
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
                        .buttonStyle(.animatedIcon)
                        .help("Unstage All")
                    }

                    Spacer()

                    // Commit button
                    if !appState.stagedFiles.isEmpty || !appState.unstagedFiles.isEmpty {
                        Button {
                            // Silently stage all unstaged files first
                            if !appState.unstagedFiles.isEmpty {
                                appState.stageAll()
                            }
                            // Capture count AFTER staging
                            committingStagedCount = appState.stagedFiles.count
                            sheetMessage = ""  // Reset sheet message
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

                    // Refresh button
                    Button {
                        appState.refreshGitStatus()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.animatedIcon)
                    .help("Refresh Status")

                    // Push button
                    Button {
                        uiState.showToast("Pushing...", icon: "arrow.up", duration: 1.0)
                        let result = appState.pushChanges()

                        if result.success {
                            if result.alreadyUpToDate {
                                uiState.showToast("Already up to date", icon: "checkmark.circle.fill", duration: 2.0)
                            } else {
                                uiState.showToast("Push successful", icon: "checkmark.circle.fill", duration: 2.0)
                            }
                        } else {
                            uiState.showToast("Push failed: \(result.error ?? "unknown")", icon: "xmark.circle", duration: 2.0)
                        }
                    } label: {
                        Image(systemName: "arrow.up.circle")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.animatedIcon)
                    .help("Push")

                    // Pull button
                    Button {
                        uiState.showToast("Pulling...", icon: "arrow.down", duration: 1.0)
                        let result = appState.pullChanges()
                        uiState.showToast(
                            result.success ? "Pull successful" : "Pull failed: \(result.error ?? "unknown")",
                            icon: result.success ? "checkmark.circle.fill" : "xmark.circle",
                            duration: 2.0
                        )
                    } label: {
                        Image(systemName: "arrow.down.circle")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.animatedIcon)
                    .help("Pull")
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
                message: $sheetMessage,
                stagedCount: committingStagedCount,
                onCommit: {
                    // Capture message before clearing
                    let messageToCommit = sheetMessage

                    // Close sheet immediately without any state changes
                    withTransaction(Transaction(animation: nil)) {
                        showCommitSheet = false
                    }

                    // Commit and refresh after sheet fully dismisses (1.2+ seconds)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        let result = appState.commitChanges(message: messageToCommit, deferRefresh: true)
                        if result.success {
                            // Refresh after commit
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                appState.refreshGitStatus()
                            }
                            // Clear both message vars after everything completes
                            sheetMessage = ""
                            commitMessage = ""
                        } else {
                            commitError = result.error
                            showError = true
                        }
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
                .buttonStyle(.animatedIcon)
                .help("Unstage")
            } else {
                Button {
                    appState.stageFile(file.url)
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.animatedIcon)
                .help("Stage")

                if file.status != .untracked {
                    Button {
                        appState.discardChanges(file.url)
                    } label: {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.animatedIcon)
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

// MARK: - Animated Icon Button Style

struct AnimatedIconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == AnimatedIconButtonStyle {
    static var animatedIcon: AnimatedIconButtonStyle {
        AnimatedIconButtonStyle()
    }
}
