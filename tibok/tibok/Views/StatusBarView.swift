//
//  StatusBarView.swift
//  tibok
//
//  Bottom status bar showing document info and save status.
//

import SwiftUI

struct StatusBarView: View {
    @EnvironmentObject var appState: AppState

    private var hasBeenSaved: Bool {
        appState.currentDocument.fileURL != nil
    }

    private var saveStatusText: String {
        if !hasBeenSaved {
            return "Not Saved"
        } else if appState.currentDocument.isModified {
            return "Modified"
        } else {
            return "Saved"
        }
    }

    private var saveStatusColor: Color {
        if !hasBeenSaved {
            return .secondary
        } else if appState.currentDocument.isModified {
            return .blue
        } else {
            return .green
        }
    }

    private var contextualTip: String {
        if appState.hasNoDocuments {
            return "⌘N new  •  ⌘O open  •  ⌘K commands"
        } else {
            return "Type / for commands  •  ⌘K palette"
        }
    }

    /// Number of uncommitted changes
    private var changeCount: Int {
        appState.stagedFiles.count + appState.unstagedFiles.count
    }

    var body: some View {
        HStack(spacing: 0) {
            // Left side - git branch (when in git repo) or word count
            if appState.isGitRepository, let branch = appState.currentBranch {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.triangle.branch")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    Text(branch)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if changeCount > 0 {
                        Text("• \(changeCount)")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }

                if !appState.hasNoDocuments {
                    Divider()
                        .padding(.horizontal, 12)
                }
            }

            // Word and character count (only when document open)
            if !appState.hasNoDocuments {
                HStack(spacing: 0) {
                    Text("\(appState.currentDocument.wordCount.formatted()) words")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Divider()
                        .padding(.horizontal, 12)

                    Text("\(appState.currentDocument.characterCount.formatted()) chars")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Center - contextual tip
            Text(contextualTip)
                .font(.system(size: 11))
                .foregroundColor(.secondary.opacity(0.6))

            Spacer()

            // Right side - save status (only when document open)
            if !appState.hasNoDocuments {
                HStack(spacing: 4) {
                    Circle()
                        .fill(saveStatusColor)
                        .frame(width: 6, height: 6)
                    Text(saveStatusText)
                        .font(.caption)
                        .foregroundColor(saveStatusColor)
                }
            }
        }
        .padding(.horizontal, 20)
        .frame(height: 26)
        .background(Color(NSColor.textBackgroundColor))
        .overlay(
            Rectangle()
                .fill(Color.primary.opacity(0.03))
        )
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color.primary.opacity(0.08)),
            alignment: .top
        )
    }
}

// Preview available in Xcode
// #Preview {
//     StatusBarView()
//         .environmentObject(AppState())
// }
