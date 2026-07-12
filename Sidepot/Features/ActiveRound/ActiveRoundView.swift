import SwiftUI
import SwiftData
import SidepotCore

/// Live round view (§18): hole navigation, score entry, live game status, running balances.
/// This build wires up the header and score-entry components against a round's data; press
/// controls, the live ledger panel, and autosave land in a Phase 4 follow-up.
struct ActiveRoundView: View {
    @Bindable var round: GolfRound
    @Environment(AppEnvironment.self) private var environment

    @State private var evaluationError: SidepotError?

    private var currentHole: HoleSnapshot? {
        round.course?.orderedHoles.first { $0.number == round.activeHoleNumber }
    }

    var body: some View {
        VStack(spacing: 0) {
            RoundProgressHeader(
                courseName: round.course?.name ?? "Round",
                holeNumber: round.activeHoleNumber,
                par: currentHole?.par ?? 4,
                holeCount: round.course?.holeCount ?? 18,
                onPrevious: { move(by: -1) },
                onNext: { move(by: 1) }
            )

            ScrollView {
                VStack(spacing: SidepotTheme.Spacing.m) {
                    if let evaluationError {
                        InlineErrorView(error: evaluationError)
                    }

                    ForEach(round.orderedRoundPlayers) { roundPlayer in
                        scoreCell(for: roundPlayer)
                    }
                }
                .padding(SidepotTheme.Spacing.m)
            }
        }
        .background(SidepotTheme.Colors.background)
        .navigationTitle("Hole \(round.activeHoleNumber)")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func scoreCell(for roundPlayer: RoundPlayer) -> some View {
        let score = (round.holeScores ?? []).first {
            $0.holeNumber == round.activeHoleNumber && $0.roundPlayer?.id == roundPlayer.id
        }
        return ScoreEntryCell(
            displayName: roundPlayer.displayNameSnapshot,
            par: currentHole?.par ?? 4,
            strokesReceived: score?.strokesReceived ?? 0,
            grossScore: Binding(
                get: { score?.grossScore },
                set: { newValue in setScore(newValue, for: roundPlayer) }
            )
        )
    }

    private func setScore(_ value: Int?, for roundPlayer: RoundPlayer) {
        guard let modelContext = round.modelContext else { return }
        if let existing = (round.holeScores ?? []).first(where: {
            $0.holeNumber == round.activeHoleNumber && $0.roundPlayer?.id == roundPlayer.id
        }) {
            existing.grossScore = value
            existing.updatedAt = .now
        } else {
            let score = HoleScore(holeNumber: round.activeHoleNumber, roundPlayer: roundPlayer, grossScore: value)
            score.round = round
            modelContext.insert(score)
        }
        recalculate()
    }

    private func move(by delta: Int) {
        let holeCount = round.course?.holeCount ?? 18
        round.activeHoleNumber = min(max(round.activeHoleNumber + delta, 1), holeCount)
    }

    private func recalculate() {
        do {
            try environment.gameEvaluationService.recalculateLedger(for: round)
            evaluationError = nil
        } catch let error as SidepotError {
            evaluationError = error
        } catch {
            evaluationError = .persistenceFailure(error.localizedDescription)
        }
    }
}

#Preview {
    let container = PersistenceController.makePreviewContainer(populate: PreviewFixtures.populate)
    let round = try! container.mainContext.fetch(FetchDescriptor<GolfRound>()).first!
    return NavigationStack {
        ActiveRoundView(round: round)
    }
    .environment(AppEnvironment())
    .modelContainer(container)
}
