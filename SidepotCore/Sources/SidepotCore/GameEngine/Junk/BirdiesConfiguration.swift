import Foundation

public struct BirdiesConfiguration: Codable, Equatable, Sendable {
    public var scoringMode: ScoringMode
    public var amountPerBirdie: Decimal
    public var eagleMultiplierEnabled: Bool
    public var eagleMultiplier: Decimal
    public var participantIDs: [UUID]

    public init(
        scoringMode: ScoringMode = .gross,
        amountPerBirdie: Decimal,
        eagleMultiplierEnabled: Bool = false,
        eagleMultiplier: Decimal = 2,
        participantIDs: [UUID]
    ) {
        self.scoringMode = scoringMode
        self.amountPerBirdie = amountPerBirdie
        self.eagleMultiplierEnabled = eagleMultiplierEnabled
        self.eagleMultiplier = eagleMultiplier
        self.participantIDs = participantIDs
    }
}
