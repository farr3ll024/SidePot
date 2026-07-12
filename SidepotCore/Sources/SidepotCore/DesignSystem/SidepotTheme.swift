import SwiftUI

/// Semantic design tokens (§19: "premium golf aesthetic... restrained green accents... Do not
/// hard-code colors directly in feature views"). Every feature view should reach for
/// `SidepotTheme` rather than a raw `Color` or `Font` literal.
public enum SidepotTheme {
    public enum Colors {
        /// Restrained fairway green — the app's one accent color. Deliberately desaturated
        /// compared to a scoreboard/casino green (§19: "Avoid casino styling... Avoid neon
        /// sportsbook visuals").
        public static let accent = Color(
            light: Color(red: 0.16, green: 0.42, blue: 0.29),
            dark: Color(red: 0.35, green: 0.62, blue: 0.47)
        )

        public static let background = Color(
            light: Color(red: 0.97, green: 0.97, blue: 0.96),
            dark: Color(red: 0.07, green: 0.08, blue: 0.08)
        )

        public static let surface = Color(
            light: .white,
            dark: Color(red: 0.12, green: 0.13, blue: 0.13)
        )

        public static let surfaceRaised = Color(
            light: .white,
            dark: Color(red: 0.16, green: 0.17, blue: 0.17)
        )

        public static let textPrimary = Color(
            light: Color(red: 0.11, green: 0.11, blue: 0.11),
            dark: Color(red: 0.95, green: 0.95, blue: 0.94)
        )

        public static let textSecondary = Color(
            light: Color(red: 0.42, green: 0.42, blue: 0.42),
            dark: Color(red: 0.66, green: 0.66, blue: 0.66)
        )

        public static let divider = Color(
            light: Color(red: 0.88, green: 0.88, blue: 0.87),
            dark: Color(red: 0.22, green: 0.23, blue: 0.23)
        )

        /// Used alongside a `+`/`-` sign and (where relevant) an icon — never as the sole signal
        /// for a positive balance (§20: "Do not convey positive/negative balance using color
        /// alone").
        public static let positive = Color(
            light: Color(red: 0.16, green: 0.42, blue: 0.29),
            dark: Color(red: 0.40, green: 0.68, blue: 0.52)
        )

        public static let negative = Color(
            light: Color(red: 0.62, green: 0.20, blue: 0.18),
            dark: Color(red: 0.85, green: 0.45, blue: 0.42)
        )

        public static let error = negative
    }

    public enum Typography {
        public static let largeTotal = Font.system(.largeTitle, design: .rounded, weight: .semibold)
        public static let title = Font.system(.title2, design: .rounded, weight: .semibold)
        public static let headline = Font.system(.headline, design: .default, weight: .semibold)
        public static let body = Font.system(.body)
        public static let caption = Font.system(.caption)

        /// Monospaced digits for any financial figure, per §20.
        public static func money(_ style: Font.TextStyle = .body, weight: Font.Weight = .semibold) -> Font {
            .system(style, design: .rounded, weight: weight).monospacedDigit()
        }
    }

    public enum Spacing {
        public static let xs: CGFloat = 4
        public static let s: CGFloat = 8
        public static let m: CGFloat = 16
        public static let l: CGFloat = 24
        public static let xl: CGFloat = 32
    }

    public enum Radius {
        public static let card: CGFloat = 16
        public static let control: CGFloat = 12
    }

    /// Minimum tap target per §20 (44x44).
    public static let minimumTapTarget: CGFloat = 44
}

extension Color {
    /// Builds a dynamic color that switches between light/dark trait variants, without requiring
    /// an asset catalog color set (SidepotCore is a Swift package, not the app bundle).
    init(light: Color, dark: Color) {
        #if canImport(UIKit)
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
        #else
        self = light
        #endif
    }
}
