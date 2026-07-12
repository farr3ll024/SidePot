import Foundation

/// Which of the two sides in a match-play format (§12, §13).
public enum MatchSide: String, Codable, Equatable, Sendable {
    case a
    case b

    var opposite: MatchSide { self == .a ? .b : .a }
}

/// The outcome of a single hole within a match: which side won it, or `nil` if it was halved.
public struct HoleResult: Equatable, Sendable {
    public let holeNumber: Int
    public let winner: MatchSide?

    public init(holeNumber: Int, winner: MatchSide?) {
        self.holeNumber = holeNumber
        self.winner = winner
    }
}

/// The state of a match-play contest at a point in time, shared by Nassau and Match Play so they
/// don't duplicate closing/dormie logic (§12, §13: "Do not duplicate Nassau logic. Reuse common
/// match-state utilities.").
public struct MatchState: Equatable, Sendable {
    public let holesWonBySideA: Int
    public let holesWonBySideB: Int
    public let holesHalved: Int
    public let holesRemaining: Int
    /// Positive: side A is up by this many holes. Negative: side B is up. Zero: all square.
    public let differential: Int
    public let isDormie: Bool
    public let isClosed: Bool

    public init(
        holesWonBySideA: Int,
        holesWonBySideB: Int,
        holesHalved: Int,
        holesRemaining: Int,
        differential: Int,
        isDormie: Bool,
        isClosed: Bool
    ) {
        self.holesWonBySideA = holesWonBySideA
        self.holesWonBySideB = holesWonBySideB
        self.holesHalved = holesHalved
        self.holesRemaining = holesRemaining
        self.differential = differential
        self.isDormie = isDormie
        self.isClosed = isClosed
    }

    public var leader: MatchSide? {
        if differential > 0 { return .a }
        if differential < 0 { return .b }
        return nil
    }

    /// `true` once the match has been fully played to its final hole and ended all square.
    public var isHalvedFinal: Bool {
        isClosed == false && holesRemaining == 0 && differential == 0
    }
}

/// Shared match-play calculations used by both the Nassau and Match Play evaluators.
public enum MatchPlayCalculator {
    /// Compares each side's best (lowest) score for a hole. For an individual match, pass a
    /// single-element array per side; for team best-ball, pass every team member's score for that
    /// hole and the lowest one represents the team (§12: "Compare best net score from each team
    /// per hole. Lower best-ball net score wins hole.").
    public static func holeWinner(sideAScores: [Int], sideBScores: [Int]) -> MatchSide? {
        guard let bestA = sideAScores.min(), let bestB = sideBScores.min() else { return nil }
        if bestA < bestB { return .a }
        if bestB < bestA { return .b }
        return nil
    }

    /// Reduces a sequence of hole results (already limited to the holes played so far within this
    /// match's range) into overall match state.
    ///
    /// - Parameter totalHolesInSegment: The number of holes this match covers in total (e.g. 9 for
    ///   a Nassau front/back segment, 18 for overall or an 18-hole match-play game).
    public static func evaluate(holeResults: [HoleResult], totalHolesInSegment: Int) -> MatchState {
        var wonA = 0
        var wonB = 0
        var halved = 0

        for result in holeResults {
            switch result.winner {
            case .a: wonA += 1
            case .b: wonB += 1
            case nil: halved += 1
            }
        }

        let played = holeResults.count
        let remaining = max(totalHolesInSegment - played, 0)
        let differential = wonA - wonB
        let isDormie = remaining > 0 && abs(differential) == remaining
        let isClosed = abs(differential) > remaining

        return MatchState(
            holesWonBySideA: wonA,
            holesWonBySideB: wonB,
            holesHalved: halved,
            holesRemaining: remaining,
            differential: differential,
            isDormie: isDormie,
            isClosed: isClosed
        )
    }

    /// The hole number (1-indexed within `holeResults`, i.e. the actual hole number of the played
    /// holes) at which the match became mathematically decided (`abs(differential) >
    /// holesRemaining`), or `nil` if it never closed early within the results given.
    public static func closingHole(holeResults: [HoleResult], totalHolesInSegment: Int) -> Int? {
        var wonA = 0
        var wonB = 0

        for (index, result) in holeResults.enumerated() {
            switch result.winner {
            case .a: wonA += 1
            case .b: wonB += 1
            case nil: break
            }
            let played = index + 1
            let remaining = totalHolesInSegment - played
            if abs(wonA - wonB) > remaining {
                return result.holeNumber
            }
        }
        return nil
    }
}
