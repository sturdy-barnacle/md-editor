//
//  WelcomeView.swift
//  tibok
//
//  First-launch onboarding for App Store users
//

import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var appState: AppState
    let onDismiss: () -> Void
    let onOpenFolder: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            // App icon and title
            VStack(spacing: 12) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 80, height: 80)

                Text("Welcome to Tibok")
                    .font(.largeTitle)
                    .fontWeight(.bold)
            }
            .padding(.top, 20)

            // Feature highlights
            VStack(alignment: .leading, spacing: 16) {
                FeatureRow(
                    icon: "folder",
                    title: "Workspace-Based Editing",
                    description: "Open a folder to see all your Markdown files in the sidebar"
                )

                FeatureRow(
                    icon: "arrow.triangle.branch",
                    title: "Built-in Git Support",
                    description: "Commit, push, and manage branches directly from the app"
                )

                FeatureRow(
                    icon: "eye",
                    title: "Live Preview",
                    description: "See your Markdown rendered in real-time as you type"
                )
            }
            .padding(.horizontal, 20)

            // Git note for App Store users
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                Text("Git features activate when you open a folder containing a .git directory")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
            .padding(.horizontal, 20)

            Spacer()

            // Action buttons
            VStack(spacing: 12) {
                Button(action: {
                    onDismiss()
                    onOpenFolder()
                }) {
                    HStack {
                        Image(systemName: "folder.badge.plus")
                        Text("Open Folder")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button("Start with Empty Editor") {
                    onDismiss()
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 24)
        }
        .frame(width: 450, height: 520)
    }
}

// MARK: - Feature Row

private struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}
