import SwiftUI
import SwiftData
import SidepotCore

/// End-of-round summary (§18): final balances and settlement. Share receipt and per-game
/// breakdowns land in a Phase 5 follow-up.
struct RoundSummaryView: View {
    let round: GolfRound
    @Environment(AppEnvironment.self) private var environment

    @State private var payments: [SettlementPaymentValue] = []
    @State private var settlementError: SidepotError?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SidepotTheme.Spacing.l) {
                Text(round.course?.name ?? "Round Summary")
                    .font(SidepotTheme.Typography.title)
                    .padding(.horizontal, SidepotTheme.Spacing.m)

                if let settlementError {
                    InlineErrorView(error: settlementError)
                        .padding(.horizontal, SidepotTheme.Spacing.m)
                } else if payments.isEmpty {
                    Text("Everyone's settled up.")
                        .font(SidepotTheme.Typography.body)
                        .foregroundStyle(SidepotTheme.Colors.textSecondary)
                        .padding(.horizontal, SidepotTheme.Spacing.m)
                } else {
                    SectionHeader("Settlement").padding(.horizontal, SidepotTheme.Spacing.m)
                    ForEach(payments) { payment in
                        HStack {
                            Text(label(for: payment.fromPlayerID))
                            Image(systemName: "arrow.right")
                                .foregroundStyle(SidepotTheme.Colors.textSecondary)
                            Text(label(for: payment.toPlayerID))
                            Spacer()
                            MoneyText(Money(amount: payment.amount))
                        }
                        .padding(.horizontal, SidepotTheme.Spacing.m)
                    }
                }
            }
            .padding(.vertical, SidepotTheme.Spacing.l)
        }
        .background(SidepotTheme.Colors.background)
        .navigationTitle("Summary")
        .task { computeSettlement() }
    }

    private func label(for roundPlayerID: UUID) -> String {
        round.orderedRoundPlayers.first { $0.id == roundPlayerID }?.displayNameSnapshot ?? "Player"
    }

    private func computeSettlement() {
        do {
            payments = try environment.settlementService.settle(round: round)
            settlementError = nil
        } catch let error as SidepotError {
            settlementError = error
        } catch {
            settlementError = .persistenceFailure(error.localizedDescription)
        }
    }
}

#Preview {
    let container = PersistenceController.makePreviewContainer(populate: PreviewFixtures.populate)
    let round = try! container.mainContext.fetch(FetchDescriptor<GolfRound>()).first!
    return NavigationStack {
        RoundSummaryView(round: round)
    }
    .environment(AppEnvironment())
    .modelContainer(container)
}
