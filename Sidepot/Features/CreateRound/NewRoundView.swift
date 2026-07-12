import SwiftUI
import SidepotCore

/// Placeholder for the five-step create-round flow described in §18 (Basics, Players, Course,
/// Games, Review). Full implementation is a Phase 3 follow-up — see README "Known Limitations."
struct NewRoundView: View {
    var body: some View {
        EmptyStateView(
            systemImage: "flag.fill",
            title: "Round setup is coming soon",
            message: "The Basics → Players → Course → Games → Review flow isn't wired up yet in this build."
        )
        .navigationTitle("New Round")
    }
}

#Preview {
    NavigationStack { NewRoundView() }
}
