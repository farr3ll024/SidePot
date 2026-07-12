import Foundation

/// A manually-recorded outcome for one hole. The hole must have an entry in `results` to count as
/// decided at all — `winnerRoundPlayerID == nil` records an explicit "no winner" (§15: "Select
/// winner, Select no winner"), which is different from the hole simply not having been recorded
/// yet (no entry present).
public struct GreenieResult: Codable, Equatable, Sendable {
    public var holeNumber: Int
    public var winnerRoundPlayerID: UUID?

    public init(holeNumber: Int, winnerRoundPlayerID: UUID?) {
        self.holeNumber = holeNumber
        self.winnerRoundPlayerID = winnerRoundPlayerID
    }
}

public struct GreeniesConfiguration: Codable, Equatable, Sendable {
    public var amount: Decimal
    public var requireParOrBetter: Bool
    public var carryoverEnabled: Bool
    /// Explicit eligible holes, or `nil` to auto-detect every par-3 in the round (§15 default).
    public var eligibleHoleNumbers: [Int]?
    public var participantIDs: [UUID]
    public var results: [GreenieResult]

    public init(
        amount: Decimal,
        requireParOrBetter: Bool = false,
        carryoverEnabled: Bool = false,
        eligibleHoleNumbers: [Int]? = nil,
        participantIDs: [UUID],
        results: [GreenieResult] = []
    ) {
        self.amount = amount
        self.requireParOrBetter = requireParOrBetter
        self.carryoverEnabled = carryoverEnabled
        self.eligibleHoleNumbers = eligibleHoleNumbers
        self.participantIDs = participantIDs
        self.results = results
    }
}
