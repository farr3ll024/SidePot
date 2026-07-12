import Foundation

/// Whether losers each pay the winner a fixed amount per skin, or every participant antes into a
/// shared per-hole pot that the winner collects (§11; pot math documented in `DEVIATIONS.md`).
public enum SkinsStakeMode: String, Codable, Equatable, Sendable {
    case fixedValuePerSkin
    case potPerHole
}

public struct SkinsConfiguration: Codable, Equatable, Sendable {
    public var scoringMode: ScoringMode
    public var stakeMode: SkinsStakeMode
    public var baseAmount: Decimal
    public var carryoversEnabled: Bool
    public var carryoverCap: Int?
    public var tiesCarry: Bool
    /// If true, a hole isn't resolved until every participant has an entered score for it (§11:
    /// "Optional validation that all players have scores before resolving a hole").
    public var requireAllScoresBeforeResolving: Bool
    /// Round-scoped player IDs competing for skins (v1 supports individual play only — §11).
    public var participantIDs: [UUID]

    public init(
        scoringMode: ScoringMode = .net,
        stakeMode: SkinsStakeMode = .fixedValuePerSkin,
        baseAmount: Decimal,
        carryoversEnabled: Bool = true,
        carryoverCap: Int? = nil,
        tiesCarry: Bool = true,
        requireAllScoresBeforeResolving: Bool = true,
        participantIDs: [UUID]
    ) {
        self.scoringMode = scoringMode
        self.stakeMode = stakeMode
        self.baseAmount = baseAmount
        self.carryoversEnabled = carryoversEnabled
        self.carryoverCap = carryoverCap
        self.tiesCarry = tiesCarry
        self.requireAllScoresBeforeResolving = requireAllScoresBeforeResolving
        self.participantIDs = participantIDs
    }
}
