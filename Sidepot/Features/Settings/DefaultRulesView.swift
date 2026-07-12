import SwiftUI
import SidepotCore

/// Placeholder for app-wide default game/stake settings that pre-fill new rounds. Full
/// implementation is a Phase 3 follow-up.
struct DefaultRulesView: View {
    var body: some View {
        EmptyStateView(
            systemImage: "slider.horizontal.3",
            title: "Default rules are coming soon",
            message: "You'll be able to set default games and stakes here so new rounds start pre-configured."
        )
        .navigationTitle("Default Rules")
    }
}

#Preview {
    NavigationStack { DefaultRulesView() }
}
