import SwiftUI

public struct SectionHeader: View {
    private let title: String
    private let actionTitle: String?
    private let action: (() -> Void)?

    public init(_ title: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.title = title
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        HStack {
            Text(title)
                .font(SidepotTheme.Typography.headline)
                .foregroundStyle(SidepotTheme.Colors.textPrimary)
            Spacer()
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(SidepotTheme.Typography.caption)
                    .tint(SidepotTheme.Colors.accent)
                    .frame(minHeight: SidepotTheme.minimumTapTarget)
            }
        }
        .accessibilityAddTraits(.isHeader)
    }
}

#Preview {
    SectionHeader("Recent Rounds", actionTitle: "See all") {}
        .padding()
}
