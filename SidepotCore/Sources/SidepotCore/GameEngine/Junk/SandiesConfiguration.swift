import Foundation

/// A manually-recorded bunker-save event. v1 never infers bunker events from score data alone
/// (§15) — the organizer marks a player eligible and confirms par-or-better by hand.
public struct SandieEntry: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var holeNumber: Int
    public var roundPlayerID: UUID
    public var madeParOrBetter: Bool

    public init(id: UUID = UUID(), holeNumber: Int, roundPlayerID: UUID, madeParOrBetter: Bool) {
        self.id = id
        self.holeNumber = holeNumber
        self.roundPlayerID = roundPlayerID
        self.madeParOrBetter = madeParOrBetter
    }
}

public struct SandiesConfiguration: Codable, Equatable, Sendable {
    public var amount: Decimal
    public var participantIDs: [UUID]
    public var entries: [SandieEntry]

    public init(amount: Decimal, participantIDs: [UUID], entries: [SandieEntry] = []) {
        self.amount = amount
        self.participantIDs = participantIDs
        self.entries = entries
    }
}
