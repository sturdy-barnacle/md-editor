import SwiftUI

struct PermissionApprovalView: View {
    let request: PluginApprovalRequest
    let onApprove: () -> Void
    let onDeny: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    init(
        request: PluginApprovalRequest,
        onApprove: @escaping () -> Void,
        onDeny: @escaping () -> Void
    ) {
        self.request = request
        self.onApprove = onApprove
        self.onDeny = onDeny
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Permission Request")
                .font(.title)
                .bold()
            
            Text(request.pluginName ?? (request.pluginIdentifier))
                .font(.headline)
            
            if let permissions = request.requestedPermissions, !permissions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Requested Permissions:")
                        .font(.subheadline)
                        .bold()
                    ForEach(permissions.indices, id: \.self) { index in
                        let permission = permissions[index]
                        Text("• " + (permission.displayName ?? String(describing: permission)))
                    }
                }
            }
            
            if let message = request.message, !message.isEmpty {
                Text(message)
                    .font(.body)
                    .padding(.top, 8)
            }
            
            Spacer()
            
            HStack {
                Spacer()
                Button("Deny", role: .destructive) {
                    onDeny()
                    dismiss()
                }
                Button("Approve") {
                    onApprove()
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(minWidth: 360)
    }
}

private extension Optional where Wrapped == [PluginPermission] {
    var wrappedOrEmpty: [PluginPermission] {
        self ?? []
    }
}

private extension PluginPermission {
    var displayName: String? {
        (self as? AnyObject)?.value(forKey: "displayName") as? String
    }
}
