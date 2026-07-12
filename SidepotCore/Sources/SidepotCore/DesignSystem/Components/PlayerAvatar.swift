import SwiftUI

public struct PlayerAvatar: View {
    private let initials: String
    private let diameter: CGFloat

    public init(initials: String, diameter: CGFloat = 40) {
        self.initials = initials
        self.diameter = diameter
    }

    public var body: some View {
        Circle()
            .fill(SidepotTheme.Colors.accent.opacity(0.16))
            .overlay {
                Text(initials)
                    .font(.system(size: diameter * 0.4, weight: .semibold, design: .rounded))
                    .foregroundStyle(SidepotTheme.Colors.accent)
            }
            .frame(width: diameter, height: diameter)
            .accessibilityHidden(true)
    }
}

#Preview {
    HStack {
        PlayerAvatar(initials: "BR")
        PlayerAvatar(initials: "MJ", diameter: 56)
    }
    .padding()
}
