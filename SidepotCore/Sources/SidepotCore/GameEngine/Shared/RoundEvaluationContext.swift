import Foundation

/// Immutable snapshot of a `RoundPlayer` used inside the game engine. Evaluators never touch
/// SwiftData models directly (§10: "Game calculations must not depend on SwiftUI [or SwiftData]").
public struct RoundPlayerSnapshot: Codable, Equatable, Identifiable, Sendable {
    /// Matches the owning `RoundPlayer.id`.
    public let id: UUID
    /// The underlying `Player.id`, stable across rounds (unlike `id`, which is per-round).
    public let playerID: UUID
    public let displayName: String
    public let handicapIndex: Double?
    public let courseHandicap: Int
    public let playingHandicap: Int
    public let teamID: UUID?
    public let startingOrder: Int

    public init(
        id: UUID,
        playerID: UUID,
        displayName: String,
        handicapIndex: Double?,
        courseHandicap: Int,
        playingHandicap: Int,
        teamID: UUID?,
        startingOrder: Int
    ) {
        self.id = id
        self.playerID = playerID
        self.displayName = displayName
        self.handicapIndex = handicapIndex
        self.courseHandicap = courseHandicap
        self.playingHandicap = playingHandicap
        self.teamID = teamID
        self.startingOrder = startingOrder
    }
}

/// Immutable snapshot of a `HoleSnapshot`.
public struct HoleSnapshotValue: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public let number: Int
    public let par: Int
    public let strokeIndex: Int?
    public let yardage: Int?

    public init(id: UUID, number: Int, par: Int, strokeIndex: Int?, yardage: Int?) {
        self.id = id
        self.number = number
        self.par = par
        self.strokeIndex = strokeIndex
        self.yardage = yardage
    }
}

/// Immutable snapshot of a `HoleScore`.
public struct HoleScoreValue: Codable, Equatable, Sendable {
    public let holeNumber: Int
    /// Matches `RoundPlayerSnapshot.id` (the round-scoped player, not `Player.id`).
    public let roundPlayerID: UUID
    public let grossScore: Int?
    public let netScore: Int?
    public let strokesReceived: Int
    public let isConceded: Bool
    public let didNotFinish: Bool

    public init(
        holeNumber: Int,
        roundPlayerID: UUID,
        grossScore: Int?,
        netScore: Int?,
        strokesReceived: Int,
        isConceded: Bool,
        didNotFinish: Bool
    ) {
        self.holeNumber = holeNumber
        self.roundPlayerID = roundPlayerID
        self.grossScore = grossScore
        self.netScore = netScore
        self.strokesReceived = strokesReceived
        self.isConceded = isConceded
        self.didNotFinish = didNotFinish
    }

    /// A score is usable by a game evaluator only if a gross score was recorded and the player
    /// didn't fail to finish the hole (§7: "Did-not-finish scores must be excluded from games
    /// that require a numeric result unless rules specify otherwise").
    public var isEntered: Bool {
        grossScore != nil && !didNotFinish
    }

    /// Net score, computed from gross minus strokes received if not already supplied.
    public var effectiveNetScore: Int? {
        if let netScore { return netScore }
        guard let grossScore else { return nil }
        return grossScore - strokesReceived
    }

    public func effectiveScore(mode: ScoringMode) -> Int? {
        switch mode {
        case .gross: return grossScore
        case .net: return effectiveNetScore
        }
    }
}

/// Everything a `GolfGameEvaluating` implementation needs to compute results for a round, as of
/// `throughHole`. Evaluators must treat this as read-only and must not depend on SwiftUI or
/// SwiftData — every field here is a plain, `Sendable` value type.
public struct RoundEvaluationContext: Sendable {
    public let roundID: UUID
    public let players: [RoundPlayerSnapshot]
    public let holes: [HoleSnapshotValue]
    public let scores: [HoleScoreValue]
    /// The highest hole number the round has recorded scores through. Holes beyond this are not
    /// yet in play and must not be evaluated.
    public let throughHole: Int

    public init(
        roundID: UUID,
        players: [RoundPlayerSnapshot],
        holes: [HoleSnapshotValue],
        scores: [HoleScoreValue],
        throughHole: Int
    ) {
        self.roundID = roundID
        self.players = players
        self.holes = holes
        self.scores = scores
        self.throughHole = throughHole
    }

    public var holeCount: Int { holes.count }

    public var orderedHoles: [HoleSnapshotValue] {
        holes.sorted { $0.number < $1.number }
    }

    /// Holes ordered by stroke index ascending (nil stroke indexes sort last, tie-broken by hole
    /// number), per §9's stroke-allocation rule. Falls back to hole-number ordering entirely when
    /// no hole carries a stroke index.
    public var holesOrderedByStrokeIndex: [HoleSnapshotValue] {
        holes.sorted { lhs, rhs in
            switch (lhs.strokeIndex, rhs.strokeIndex) {
            case let (l?, r?):
                return l != r ? l < r : lhs.number < rhs.number
            case (nil, nil):
                return lhs.number < rhs.number
            case (nil, _):
                return false
            case (_, nil):
                return true
            }
        }
    }

    public func player(_ id: UUID) -> RoundPlayerSnapshot? {
        players.first { $0.id == id }
    }

    public func scores(forHole holeNumber: Int) -> [HoleScoreValue] {
        scores.filter { $0.holeNumber == holeNumber }
    }

    public func score(for roundPlayerID: UUID, hole holeNumber: Int) -> HoleScoreValue? {
        scores.first { $0.roundPlayerID == roundPlayerID && $0.holeNumber == holeNumber }
    }
}

/// Whether a game compares gross or net scores.
public enum ScoringMode: String, Codable, Equatable, Sendable {
    case gross
    case net
}
