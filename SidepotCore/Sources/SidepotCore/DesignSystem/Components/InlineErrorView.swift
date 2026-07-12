import SwiftUI

/// Surfaces a `SidepotError` inline, per §21: explain what happened, state how to fix it, avoid
/// jargon.
public struct InlineErrorView: View {
    private let title: String
    private let message: String?

    public init(title: String, message: String? = nil) {
        self.title = title
        self.message = message
    }

    public init(error: SidepotError) {
        self.title = error.errorDescription ?? "Something went wrong."
        self.message = error.recoverySuggestion
    }

    public var body: some View {
        HStack(alignment: .top, spacing: SidepotTheme.Spacing.s) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(SidepotTheme.Colors.error)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(SidepotTheme.Typography.headline)
                    .foregroundStyle(SidepotTheme.Colors.textPrimary)
                if let message {
                    Text(message)
                        .font(SidepotTheme.Typography.caption)
                        .foregroundStyle(SidepotTheme.Colors.textSecondary)
                }
            }
            Spacer()
        }
        .padding(SidepotTheme.Spacing.m)
        .background(SidepotTheme.Colors.error.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: SidepotTheme.Radius.control))
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    InlineErrorView(error: .incompleteScores("Ryan hasn't entered a score for hole 7."))
        .padding()
}
