import Foundation

/// Pure, deterministic handicap math (§9). Every function here is a plain calculation with no
/// dependency on SwiftData or SwiftUI, so it can be exhaustively unit tested and reused by any
/// evaluator that needs strokes-received data.
public enum HandicapEngine {
    /// `Course Handicap = Handicap Index × (Slope Rating / 113) + (Course Rating − Par)`,
    /// rounded to the nearest whole number using golf's "round half up" convention (0.5 always
    /// rounds toward positive infinity, e.g. both `10.5 → 11` and `-0.5 → 0`).
    public static func courseHandicap(
        handicapIndex: Double,
        slopeRating: Double,
        courseRating: Double,
        par: Int
    ) -> Int {
        let raw = handicapIndex * (slopeRating / 113.0) + (courseRating - Double(par))
        return roundHalfUp(raw)
    }

    /// Applies a game's allowance percentage (e.g. 90% for a two-team format) to a course
    /// handicap, again rounding half up.
    public static func playingHandicap(courseHandicap: Int, allowancePercentage: Double) -> Int {
        roundHalfUp(Double(courseHandicap) * allowancePercentage)
    }

    /// Computes strokes received per hole for every player in `playingHandicaps`, relative to the
    /// lowest playing handicap *within that set* — callers decide what "the match" means by which
    /// players they pass in: the whole round's field for round-level net scoring, or just two
    /// Nassau sides for that match's strokes (see `DEVIATIONS.md`).
    ///
    /// - Parameters:
    ///   - playingHandicaps: Playing handicap per round-scoped player ID. Supports plus handicaps
    ///     (negative values) — the lowest value in the set always receives zero strokes, even if
    ///     it's negative.
    ///   - holes: The holes strokes may be allocated across. Allocation order is stroke-index
    ///     ascending (§9); if the difference exceeds the hole count, allocation wraps back to the
    ///     first hole in that order and gives second (or further) strokes.
    ///   - manualOverrides: Explicit hole-by-hole stroke counts that bypass calculation entirely
    ///     for a given player (§9: "Support manual hole-by-hole stroke overrides").
    /// - Returns: For each player ID, a map of hole number to strokes received on that hole.
    public static func strokesReceived(
        playingHandicaps: [UUID: Int],
        holes: [HoleSnapshotValue],
        manualOverrides: [UUID: [Int: Int]] = [:]
    ) -> [UUID: [Int: Int]] {
        guard let lowest = playingHandicaps.values.min() else { return [:] }

        let orderedHoles = orderByStrokeIndex(holes)
        var result: [UUID: [Int: Int]] = [:]

        for (playerID, handicap) in playingHandicaps {
            if let override = manualOverrides[playerID] {
                result[playerID] = override
                continue
            }
            let difference = max(handicap - lowest, 0)
            result[playerID] = allocate(strokes: difference, orderedHoles: orderedHoles)
        }

        return result
    }

    /// Holes ordered for stroke allocation: ascending stroke index, nils sorted last and
    /// tie-broken by hole number. Works unmodified for both 18-hole rounds and a selected nine —
    /// §9's "normalized ordering" for a 9-hole round falls out naturally from sorting just the
    /// holes that were actually passed in.
    static func orderByStrokeIndex(_ holes: [HoleSnapshotValue]) -> [HoleSnapshotValue] {
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

    private static func allocate(strokes: Int, orderedHoles: [HoleSnapshotValue]) -> [Int: Int] {
        var perHole = Dictionary(uniqueKeysWithValues: orderedHoles.map { ($0.number, 0) })
        guard strokes > 0, !orderedHoles.isEmpty else { return perHole }

        var remaining = strokes
        var index = 0
        while remaining > 0 {
            let hole = orderedHoles[index % orderedHoles.count]
            perHole[hole.number, default: 0] += 1
            remaining -= 1
            index += 1
        }
        return perHole
    }

    /// Rounds half up (toward positive infinity), matching accepted WHS course-handicap rounding
    /// behavior — unlike `Decimal`/`Double`'s default "round half away from zero," this rounds
    /// `-0.5` to `0`, not `-1`.
    static func roundHalfUp(_ value: Double) -> Int {
        Int((value + 0.5).rounded(.down))
    }
}
