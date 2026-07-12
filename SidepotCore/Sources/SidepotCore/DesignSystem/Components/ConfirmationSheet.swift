import SwiftUI

/// A lightweight confirmation prompt for destructive or hard-to-reverse actions (abandon round,
/// reopen a completed round, archive a player).
public struct ConfirmationSheet: View {
    private let title: String
    private let message: String
    private let confirmTitle: String
    private let isDestructive: Bool
    private let onConfirm: () -> Void
    private let onCancel: () -> Void

    public init(
        title: String,
        message: String,
        confirmTitle: String,
        isDestructive: Bool = false,
        onConfirm: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.title = title
        self.message = message
        self.confirmTitle = confirmTitle
        self.isDestructive = isDestructive
        self.onConfirm = onConfirm
        self.onCancel = onCancel
    }

    public var body: some View {
        VStack(spacing: SidepotTheme.Spacing.l) {
            VStack(spacing: SidepotTheme.Spacing.s) {
                Text(title)
                    .font(SidepotTheme.Typography.title)
                    .foregroundStyle(SidepotTheme.Colors.textPrimary)
                Text(message)
                    .font(SidepotTheme.Typography.body)
                    .foregroundStyle(SidepotTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: SidepotTheme.Spacing.s) {
                Button(role: isDestructive ? .destructive : nil) {
                    onConfirm()
                } label: {
                    Text(confirmTitle)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: SidepotTheme.minimumTapTarget)
                }
                .buttonStyle(.borderedProminent)
                .tint(isDestructive ? SidepotTheme.Colors.error : SidepotTheme.Colors.accent)

                SecondaryButton("Cancel", action: onCancel)
            }
        }
        .padding(SidepotTheme.Spacing.l)
        .presentationDetents([.medium])
    }
}

#Preview {
    ConfirmationSheet(
        title: "Abandon Round?",
        message: "This round's scores and bets will be kept, but it won't count toward standings.",
        confirmTitle: "Abandon Round",
        isDestructive: true,
        onConfirm: {},
        onCancel: {}
    )
}
