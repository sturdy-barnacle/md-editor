//
//  TabBarView.swift
//  tibok
//
//  Tab bar for managing multiple open documents.
//

import SwiftUI

struct TabBarView: View {
    @EnvironmentObject var appState: AppState
    @State private var hoveredTabID: UUID?
    @State private var draggedTab: Document?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(appState.documents) { doc in
                    TabItemView(
                        document: doc,
                        isActive: doc.id == appState.activeDocumentID,
                        isHovered: doc.id == hoveredTabID,
                        onSelect: { appState.switchToTab(id: doc.id) },
                        onClose: { appState.closeTab(id: doc.id) }
                    )
                    .onHover { hovering in
                        hoveredTabID = hovering ? doc.id : nil
                    }
                    .onDrag {
                        draggedTab = doc
                        return NSItemProvider(object: doc.id.uuidString as NSString)
                    }
                    .onDrop(of: [.text], delegate: TabDropDelegate(
                        document: doc,
                        documents: appState.documents,
                        draggedTab: $draggedTab,
                        moveTab: appState.moveTab
                    ))
                    .contextMenu {
                        Button("Close") {
                            appState.closeTab(id: doc.id)
                        }
                        Button("Close Others") {
                            appState.closeOtherTabs(except: doc.id)
                        }
                        Button("Close All") {
                            appState.closeAllTabs()
                        }
                        Divider()
                        if let url = doc.fileURL {
                            Button("Reveal in Finder") {
                                appState.revealInFinder(url)
                            }
                            Button("Copy Path") {
                                appState.copyPathToClipboard(url)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 8)
        }
        .frame(height: 28)
        .background(Color(NSColor.textBackgroundColor))
        .overlay(
            Rectangle()
                .fill(Color.primary.opacity(0.03))
                .allowsHitTesting(false)
        )
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color.primary.opacity(0.08)),
            alignment: .bottom
        )
    }
}

// MARK: - Tab Item View

struct TabItemView: View {
    let document: Document
    let isActive: Bool
    let isHovered: Bool
    let onSelect: () -> Void
    let onClose: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 6) {
                // Modified indicator (always reserve space)
                Circle()
                    .fill(Color.primary.opacity(0.5))
                    .frame(width: 6, height: 6)
                    .opacity(document.isModified ? 1.0 : 0)
                    .animation(.easeInOut(duration: 0.15), value: document.isModified)

                // Filename
                Text(document.fileURL?.lastPathComponent ?? "Untitled.md")
                    .font(.system(size: 12))
                    .lineLimit(1)
                    .foregroundColor(isActive ? .primary : .secondary)

                // Close button (always reserve space, show on hover/active)
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.animatedIcon)
                .frame(width: 14, height: 14)
                .contentShape(Rectangle())
                .opacity(isHovered || isActive ? 1.0 : 0)
                .animation(.easeInOut(duration: 0.15), value: isHovered || isActive)
                .allowsHitTesting(isHovered || isActive)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(isActive ? Color.primary.opacity(0.08) : (isHovered ? Color.primary.opacity(0.04) : Color.clear))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Tab Drop Delegate

struct TabDropDelegate: DropDelegate {
    let document: Document
    let documents: [Document]
    @Binding var draggedTab: Document?
    let moveTab: (Int, Int) -> Void

    func performDrop(info: DropInfo) -> Bool {
        draggedTab = nil
        return true
    }

    func dropEntered(info: DropInfo) {
        guard let draggedTab = draggedTab,
              draggedTab.id != document.id,
              let fromIndex = documents.firstIndex(where: { $0.id == draggedTab.id }),
              let toIndex = documents.firstIndex(where: { $0.id == document.id }) else {
            return
        }

        withAnimation(.easeInOut(duration: 0.2)) {
            moveTab(fromIndex, toIndex)
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
}
