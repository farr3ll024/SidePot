import Foundation
import SwiftData

/// The persisted record of one round of golf: its course, players, scores, configured games, and
/// everything the game engine derives from them. Sidepot allows at most one `active` round at a
/// time (§22).
@Model
public final class GolfRound {
    public var id: UUID = UUID()
    public var status: RoundStatus = RoundStatus.draft
    public var startedAt: Date?
    public var completedAt: Date?
    public var scheduledDate: Date = Date.now
    public var createdAt: Date = Date.now
    public var updatedAt: Date = Date.now
    public var currencyCode: String = "USD"
    public var usesRealCurrencyLabels: Bool = true
    public var notes: String?
    /// Current hole the round has progressed to; restored on relaunch (§22).
    public var activeHoleNumber: Int = 1

    @Relationship(deleteRule: .cascade, inverse: \CourseSnapshot.round)
    public var course: CourseSnapshot?

    @Relationship(deleteRule: .cascade, inverse: \RoundPlayer.round)
    public var roundPlayers: [RoundPlayer]? = []

    @Relationship(deleteRule: .cascade, inverse: \HoleScore.round)
    public var holeScores: [HoleScore]? = []

    @Relationship(deleteRule: .cascade, inverse: \GameConfiguration.owningRound)
    public var games: [GameConfiguration]? = []

    @Relationship(deleteRule: .cascade, inverse: \LedgerEntry.round)
    public var ledgerEntries: [LedgerEntry]? = []

    @Relationship(deleteRule: .cascade, inverse: \SettlementPayment.round)
    public var settlements: [SettlementPayment]? = []

    public var group: GolfGroup?

    public init(
        id: UUID = UUID(),
        status: RoundStatus = .draft,
        startedAt: Date? = nil,
        completedAt: Date? = nil,
        scheduledDate: Date = .now,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        currencyCode: String = "USD",
        usesRealCurrencyLabels: Bool = true,
        notes: String? = nil,
        activeHoleNumber: Int = 1
    ) {
        self.id = id
        self.status = status
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.scheduledDate = scheduledDate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.currencyCode = currencyCode
        self.usesRealCurrencyLabels = usesRealCurrencyLabels
        self.notes = notes
        self.activeHoleNumber = activeHoleNumber
    }

    public var orderedRoundPlayers: [RoundPlayer] {
        (roundPlayers ?? []).sorted { $0.startingOrder < $1.startingOrder }
    }

    /// Builds the pure-value context the game engine evaluates against, as of `throughHole`
    /// (defaults to the round's current active hole).
    public func evaluationContext(throughHole: Int? = nil) -> RoundEvaluationContext {
        RoundEvaluationContext(
            roundID: id,
            players: orderedRoundPlayers.map(\.asSnapshot),
            holes: (course?.holes ?? []).map(\.asValue),
            scores: (holeScores ?? []).map(\.asValue),
            throughHole: throughHole ?? activeHoleNumber
        )
    }

    public func validate() throws {
        guard let course else {
            throw SidepotError.invalidRound("This round has no course set up.")
        }
        try course.validate()
        guard (roundPlayers?.count ?? 0) >= 2 else {
            throw SidepotError.invalidRound("A round needs at least two players.")
        }
    }
}
