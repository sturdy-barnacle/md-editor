import Foundation
import SwiftUI

@MainActor
class UIStateService: ObservableObject {
    static let shared = UIStateService()

    // MARK: - Toast Notifications

    @Published var toastMessage: String?
    @Published var toastIcon: String?
    private var toastDismissTask: Task<Void, Never>?

    private init() {}

    func showToast(_ message: String, icon: String? = nil, duration: TimeInterval = 1.5) {
        toastDismissTask?.cancel()
        toastMessage = message
        toastIcon = icon

        toastDismissTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            if !Task.isCancelled {
                withAnimation(.easeOut(duration: 0.2)) {
                    self.toastMessage = nil
                    self.toastIcon = nil
                }
            }
        }
    }
}
