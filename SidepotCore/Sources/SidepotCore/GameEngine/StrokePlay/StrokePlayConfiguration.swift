import Foundation

public enum TieHandling: String, Codable, Equatable, Sendable {
    case push
    case splitPot
}

public struct StrokePlayConfiguration: Codable, Equatable, Sendable {
    public var scoringMode: ScoringMode
    public var stakeAmount: Decimal
    /// Accepted for forward compatibility; the only payout mechanic the spec describes (§14) is
    /// already what this evaluator implements regardless of this flag — see `DEVIATIONS.md`.
    public var winnerTakeAll: Bool
    public var tieHandling: TieHandling
    public var participantIDs: [UUID]

    public init(
        scoringMode: ScoringMode = .net,
        stakeAmount: Decimal,
        winnerTakeAll: Bool = true,
        tieHandling: TieHandling = .push,
        participantIDs: [UUID]
    ) {
        self.scoringMode = scoringMode
        self.stakeAmount = stakeAmount
        self.winnerTakeAll = winnerTakeAll
        self.tieHandling = tieHandling
        self.participantIDs = participantIDs
    }
}
