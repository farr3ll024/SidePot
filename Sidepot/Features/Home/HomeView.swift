import SwiftUI
import SwiftData
import SidepotCore

struct HomeView: View {
    @Query(filter: #Predicate<GolfRound> { $0.status == RoundStatus.active })
    private var activeRounds: [GolfRound]

    @Query(sort: \GolfGroup.name) private var groups: [GolfGroup]

    @Query(
        filter: #Predicate<GolfRound> { $0.status == RoundStatus.completed },
        sort: \GolfRound.completedAt,
        order: .reverse
    )
    private var recentRounds: [GolfRound]

    @Query private var players: [Player]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SidepotTheme.Spacing.l) {
                if let active = activeRounds.first {
                    activeRoundCard(active)
                }

                if players.count < 2 {
                    EmptyStateView(
                        systemImage: "figure.golf",
                        title: "Add a couple of players first",
                        message: "Sidepot needs at least two players to start tracking a round.",
                        actionTitle: "Add Players",
                        action: {}
                    )
                } else {
                    NavigationLink {
                        Text("New Round setup is coming in a follow-up build.")
                            .foregroundStyle(SidepotTheme.Colors.textSecondary)
                            .padding()
                    } label: {
                        PrimaryButton("New Round") {}
                            .allowsHitTesting(false)
                    }
                    .padding(.horizontal, SidepotTheme.Spacing.m)
                }

                SectionHeader("Groups")
                    .padding(.horizontal, SidepotTheme.Spacing.m)
                if groups.isEmpty {
                    Text("No groups yet.")
                        .font(SidepotTheme.Typography.caption)
                        .foregroundStyle(SidepotTheme.Colors.textSecondary)
                        .padding(.horizontal, SidepotTheme.Spacing.m)
                } else {
                    ForEach(groups) { group in
                        Text(group.name)
                            .font(SidepotTheme.Typography.body)
                            .padding(.horizontal, SidepotTheme.Spacing.m)
                    }
                }

                SectionHeader("Recent Rounds")
                    .padding(.horizontal, SidepotTheme.Spacing.m)
                if recentRounds.isEmpty {
                    Text("Completed rounds will show up here.")
                        .font(SidepotTheme.Typography.caption)
                        .foregroundStyle(SidepotTheme.Colors.textSecondary)
                        .padding(.horizontal, SidepotTheme.Spacing.m)
                } else {
                    ForEach(recentRounds.prefix(3)) { round in
                        Text(round.course?.name ?? "Round")
                            .font(SidepotTheme.Typography.body)
                            .padding(.horizontal, SidepotTheme.Spacing.m)
                    }
                }
            }
            .padding(.vertical, SidepotTheme.Spacing.m)
        }
        .background(SidepotTheme.Colors.background)
        .navigationTitle("Sidepot")
    }

    private func activeRoundCard(_ round: GolfRound) -> some View {
        VStack(alignment: .leading, spacing: SidepotTheme.Spacing.s) {
            SectionHeader("Active Round")
            Text(round.course?.name ?? "In progress")
                .font(SidepotTheme.Typography.headline)
            Text("Hole \(round.activeHoleNumber) of \(round.course?.holeCount ?? 18)")
                .font(SidepotTheme.Typography.caption)
                .foregroundStyle(SidepotTheme.Colors.textSecondary)
        }
        .padding(SidepotTheme.Spacing.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SidepotTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: SidepotTheme.Radius.card))
        .padding(.horizontal, SidepotTheme.Spacing.m)
    }
}

#Preview("Populated") {
    NavigationStack { HomeView() }
        .modelContainer(PersistenceController.makePreviewContainer(populate: PreviewFixtures.populate))
}

#Preview("Empty") {
    NavigationStack { HomeView() }
        .modelContainer(PersistenceController.makePreviewContainer())
}
