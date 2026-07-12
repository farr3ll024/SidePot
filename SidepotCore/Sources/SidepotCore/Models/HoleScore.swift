import Foundation
import SwiftData

/// One player's recorded result on one hole of one round.
@Model
public final class HoleScore {
    public var id: UUID = UUID()
    public var holeNumber: Int = 1
    public var roundPlayer: RoundPlayer?
    public var grossScore: Int?
    public var netScore: Int?
    public var strokesReceived: Int = 0
    public var isConceded: Bool = false
    public var didNotFinish: Bool = false
    public var updatedAt: Date = Date.now

    public var round: GolfRound?

    public init(
        id: UUID = UUID(),
        holeNumber: Int,
        roundPlayer: RoundPlayer?,
        grossScore: Int? = nil,
        netScore: Int? = nil,
        strokesReceived: Int = 0,
        isConceded: Bool = false,
        didNotFinish: Bool = false,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.holeNumber = holeNumber
        self.roundPlayer = roundPlayer
        self.grossScore = grossScore
        self.netScore = netScore
        self.strokesReceived = strokesReceived
        self.isConceded = isConceded
        self.didNotFinish = didNotFinish
        self.updatedAt = updatedAt
    }

    public func validate() throws {
        guard (1...18).contains(holeNumber) else {
            throw SidepotError.invalidRound("Hole number must be between 1 and 18.")
        }
        if let grossScore, !(1...20).contains(grossScore) {
            throw SidepotError.incompleteScores("Gross score must be between 1 and 20.")
        }
    }

    public var asValue: HoleScoreValue {
        HoleScoreValue(
            holeNumber: holeNumber,
            roundPlayerID: roundPlayer?.id ?? id,
            grossScore: grossScore,
            netScore: netScore,
            strokesReceived: strokesReceived,
            isConceded: isConceded,
            didNotFinish: didNotFinish
        )
    }
}
