import SwiftUI

public struct SecondaryButton: View {
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
        .buttonStyle(.bordered)
        .tint(SidepotTheme.Colors.accent)
        .disabled(!isEnabled)
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    SecondaryButton("Skip") {}
        .padding()
}
