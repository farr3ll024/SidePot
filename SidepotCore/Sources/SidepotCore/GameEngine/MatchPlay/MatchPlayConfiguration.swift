import Foundation

public enum MatchPlayFormat: String, Codable, Equatable, Sendable {
    case individual
    case twoTeams
}

public struct MatchPlayConfiguration: Codable, Equatable, Sendable {
    public var format: MatchPlayFormat
    public var scoringMode: ScoringMode
    public var stakeAmount: Decimal
    /// Round-scoped player IDs on side A (exactly one for `.individual`).
    public var sideAPlayerIDs: [UUID]
    /// Round-scoped player IDs on side B (exactly one for `.individual`).
    public var sideBPlayerIDs: [UUID]

    public init(
        format: MatchPlayFormat = .individual,
        scoringMode: ScoringMode = .net,
        stakeAmount: Decimal,
        sideAPlayerIDs: [UUID],
        sideBPlayerIDs: [UUID]
    ) {
        self.format = format
        self.scoringMode = scoringMode
        self.stakeAmount = stakeAmount
        self.sideAPlayerIDs = sideAPlayerIDs
        self.sideBPlayerIDs = sideBPlayerIDs
    }
}
