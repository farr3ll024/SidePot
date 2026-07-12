import Foundation
import Testing
@testable import SidepotCore

@Suite("HandicapEngine")
struct HandicapEngineTests {
    @Test("Zero handicap computes a course handicap of zero on a scratch course")
    func zeroHandicap() {
        let result = HandicapEngine.courseHandicap(handicapIndex: 0, slopeRating: 113, courseRating: 72, par: 72)
        #expect(result == 0)
    }

    @Test("Plus handicap produces a negative course handicap")
    func plusHandicap() {
        // -2 index, neutral slope/rating/par -> course handicap of -2.
        let result = HandicapEngine.courseHandicap(handicapIndex: -2, slopeRating: 113, courseRating: 72, par: 72)
        #expect(result == -2)
    }

    @Test("Course handicap rounds half up, including for negative values")
    func roundingHalfUp() {
        #expect(HandicapEngine.roundHalfUp(10.5) == 11)
        #expect(HandicapEngine.roundHalfUp(10.4) == 10)
        #expect(HandicapEngine.roundHalfUp(-0.5) == 0)
        #expect(HandicapEngine.roundHalfUp(-1.5) == -1)
    }

    @Test("Playing handicap applies an allowance percentage")
    func playingHandicapAllowance() {
        #expect(HandicapEngine.playingHandicap(courseHandicap: 20, allowancePercentage: 0.9) == 18)
        #expect(HandicapEngine.playingHandicap(courseHandicap: 10, allowancePercentage: 1.0) == 10)
    }

    @Test("Strokes received: more than 18 strokes wraps around to a second stroke per hole")
    func moreThan18Strokes() {
        let scratch = UUID()
        let highHandicap = UUID()
        let holes = TestSupport.holes(count: 18)

        let result = HandicapEngine.strokesReceived(
            playingHandicaps: [scratch: 0, highHandicap: 25],
            holes: holes
        )

        let strokes = result[highHandicap] ?? [:]
        #expect(strokes.count == 18)
        // Holes with stroke index 1...7 receive a second stroke; 8...18 receive one.
        for holeNumber in 1...7 {
            #expect(strokes[holeNumber] == 2)
        }
        for holeNumber in 8...18 {
            #expect(strokes[holeNumber] == 1)
        }
        #expect((result[scratch] ?? [:]).values.allSatisfy { $0 == 0 })
    }

    @Test("Team handicap differences: everyone's strokes are relative to the lowest in the set")
    func teamHandicapDifferences() {
        let p1 = UUID(), p2 = UUID(), p3 = UUID(), p4 = UUID()
        let holes = TestSupport.holes(count: 18)

        let result = HandicapEngine.strokesReceived(
            playingHandicaps: [p1: 5, p2: 12, p3: 18, p4: 22],
            holes: holes
        )

        #expect((result[p1] ?? [:]).values.reduce(0, +) == 0)
        #expect((result[p2] ?? [:]).values.reduce(0, +) == 7)
        #expect((result[p3] ?? [:]).values.reduce(0, +) == 13)
        #expect((result[p4] ?? [:]).values.reduce(0, +) == 17)
    }

    @Test("9-hole allocation uses stroke indexes 1...9 when provided")
    func nineHoleAllocation() {
        let scratch = UUID()
        let mid = UUID()
        let holes = TestSupport.holes(count: 9, strokeIndexes: [3, 1, 9, 7, 5, 2, 8, 4, 6])

        let result = HandicapEngine.strokesReceived(playingHandicaps: [scratch: 0, mid: 5], holes: holes)
        let strokes = result[mid] ?? [:]

        // The 5 lowest stroke-index holes should each receive exactly one stroke.
        let holesWithStrokes = strokes.filter { $0.value == 1 }.map(\.key).sorted()
        // Stroke indexes 1..5 correspond to holes 2,6,1,8,5 (from the strokeIndexes array above).
        #expect(Set(holesWithStrokes) == Set([2, 6, 1, 8, 5]))
        #expect(strokes.values.reduce(0, +) == 5)
    }

    @Test("Missing stroke indexes fall back to hole-number ordering")
    func missingStrokeIndexes() {
        let scratch = UUID()
        let mid = UUID()
        let holes = (1...18).map { HoleSnapshotValue(id: UUID(), number: $0, par: 4, strokeIndex: nil, yardage: nil) }

        let result = HandicapEngine.strokesReceived(playingHandicaps: [scratch: 0, mid: 3], holes: holes)
        let strokes = result[mid] ?? [:]

        #expect(strokes[1] == 1)
        #expect(strokes[2] == 1)
        #expect(strokes[3] == 1)
        #expect(strokes[4] == 0)
    }

    @Test("Manual override bypasses calculation entirely")
    func manualOverride() {
        let scratch = UUID()
        let mid = UUID()
        let holes = TestSupport.holes(count: 18)
        let override: [Int: Int] = [1: 1, 5: 1]

        let result = HandicapEngine.strokesReceived(
            playingHandicaps: [scratch: 0, mid: 12],
            holes: holes,
            manualOverrides: [mid: override]
        )

        #expect(result[mid] == override)
    }
}
