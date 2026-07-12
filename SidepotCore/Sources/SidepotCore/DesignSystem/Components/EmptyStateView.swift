import SwiftUI

public struct EmptyStateView: View {
    private let systemImage: String
    private let title: String
    private let message: String
    private let actionTitle: String?
    private let action: (() -> Void)?

    public init(
        systemImage: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.systemImage = systemImage
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        VStack(spacing: SidepotTheme.Spacing.m) {
            Image(systemName: systemImage)
                .font(.system(size: 40))
                .foregroundStyle(SidepotTheme.Colors.accent)
            Text(title)
                .font(SidepotTheme.Typography.title)
                .foregroundStyle(SidepotTheme.Colors.textPrimary)
            Text(message)
                .font(SidepotTheme.Typography.body)
                .foregroundStyle(SidepotTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
            if let actionTitle, let action {
                PrimaryButton(actionTitle, action: action)
                    .padding(.top, SidepotTheme.Spacing.s)
                    .frame(maxWidth: 240)
            }
        }
        .padding(SidepotTheme.Spacing.xl)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    EmptyStateView(
        systemImage: "figure.golf",
        title: "No rounds yet",
        message: "Add a couple of players, then start your first round to begin tracking side bets.",
        actionTitle: "New Round",
        action: {}
    )
}
