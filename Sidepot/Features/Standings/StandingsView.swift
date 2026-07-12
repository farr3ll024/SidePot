import SwiftUI
import SidepotCore

/// §18: season standings (rounds played, net winnings, win rate, streaks). Computing these from
/// completed-round history is a Phase 5 follow-up — this build establishes the tab and empty
/// state.
struct StandingsView: View {
    var body: some View {
        EmptyStateView(
            systemImage: "chart.bar.fill",
            title: "No standings yet",
            message: "Complete a round to start tracking season totals, win rate, and streaks."
        )
        .navigationTitle("Standings")
    }
}

#Preview {
    NavigationStack { StandingsView() }
}
