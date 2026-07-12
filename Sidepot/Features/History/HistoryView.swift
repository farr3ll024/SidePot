import SwiftUI
import SwiftData
import SidepotCore

/// §18: completed-round history. Group/player/course/date filters land in a Phase 5 follow-up.
struct HistoryView: View {
    @Query(
        filter: #Predicate<GolfRound> { $0.status == RoundStatus.completed },
        sort: \GolfRound.completedAt,
        order: .reverse
    )
    private var rounds: [GolfRound]

    var body: some View {
        Group {
            if rounds.isEmpty {
                EmptyStateView(
                    systemImage: "clock.arrow.circlepath",
                    title: "No rounds yet",
                    message: "Finished rounds will show up here with the winner and your balance."
                )
            } else {
                List(rounds) { round in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(round.course?.name ?? "Round")
                            .font(SidepotTheme.Typography.headline)
                        if let completedAt = round.completedAt {
                            Text(completedAt.formatted(date: .abbreviated, time: .omitted))
                                .font(SidepotTheme.Typography.caption)
                                .foregroundStyle(SidepotTheme.Colors.textSecondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("History")
    }
}

#Preview("Empty") {
    NavigationStack { HistoryView() }
        .modelContainer(PersistenceController.makePreviewContainer())
}
