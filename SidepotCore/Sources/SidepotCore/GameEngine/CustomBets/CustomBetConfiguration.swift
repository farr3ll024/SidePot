import Foundation

public enum CustomBetStatus: String, Codable, Equatable, Sendable {
    case pending
    case resolved
    case void
}

/// A one-off side bet (closest to pin, longest drive, first birdie, ...) with a simple
/// winner-take-all(-or-split) payout (§16).
public struct CustomBetConfiguration: Codable, Equatable, Sendable {
    public var name: String
    public var amount: Decimal
    public var participantIDs: [UUID]
    public var winnerIDs: [UUID]
    public var holeNumber: Int?
    public var notes: String?
    public var status: CustomBetStatus

    public init(
        name: String,
        amount: Decimal,
        participantIDs: [UUID],
        winnerIDs: [UUID] = [],
        holeNumber: Int? = nil,
        notes: String? = nil,
        status: CustomBetStatus = .pending
    ) {
        self.name = name
        self.amount = amount
        self.participantIDs = participantIDs
        self.winnerIDs = winnerIDs
        self.holeNumber = holeNumber
        self.notes = notes
        self.status = status
    }
}
