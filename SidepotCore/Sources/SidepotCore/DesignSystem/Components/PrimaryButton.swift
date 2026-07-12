import SwiftUI

public struct PrimaryButton: View {
    private let title: String
    private let isEnabled: Bool
    private let action: () -> Void

    public init(_ title: String, isEnabled: Bool = true, action: @escaping () -> Void) {
        self.title = title
        self.isEnabled = isEnabled
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(SidepotTheme.Typography.headline)
                .frame(maxWidth: .infinity)
                .frame(minHeight: SidepotTheme.minimumTapTarget)
        }
        .buttonStyle(.borderedProminent)
        .tint(SidepotTheme.Colors.accent)
        .disabled(!isEnabled)
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    VStack(spacing: 12) {
        PrimaryButton("Start Round") {}
        PrimaryButton("Disabled", isEnabled: false) {}
    }
    .padding()
}
