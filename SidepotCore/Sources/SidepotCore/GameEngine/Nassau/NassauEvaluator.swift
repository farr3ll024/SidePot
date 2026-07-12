import Foundation

/// Front/back/overall Nassau with manual and automatic two-down presses (§12). This is the
/// highest-risk evaluator in the app per the spec, so every rule is implemented as a small, pure,
/// independently-testable step:
///
/// 1. `segmentRange` decides which segments even apply for this round's hole count.
/// 2. `buildResults` turns raw scores into hole-by-hole winners for a given hole range.
/// 3. `MatchPlayCalculator.evaluate` (shared with Match Play) turns hole results into `MatchState`.
/// 4. `derivePresses` re-derives the full set of presses — automatic and manual — from the base
///    match's results plus `configuration.manualPresses`, from scratch, every time. Nothing about
///    presses is held as mutable evaluator state, so recalculating after a score edit
///    automatically creates or removes presses as needed (§26: "Editing a prior score removes or
///    creates a press deterministically").
/// 5. `ledgerEntries` turns a resolved (closed or fully played) match into equal-share payments.
///
/// Net scores are read directly from `HoleScoreValue.effectiveScore(mode:)`, i.e. from strokes
/// already allocated and persisted on `HoleScore` by the app layer at round setup
/// (`HandicapEngine.strokesReceived`) — the evaluator does not recompute handicap strokes itself.
public struct NassauEvaluator: GolfGameEvaluating {
    public init() {}

    public func evaluate(
        gameID: UUID,
        context: RoundEvaluationContext,
        configuration: NassauConfiguration
    ) throws -> GameEvaluationResult {
        guard !configuration.sideAPlayerIDs.isEmpty, !configuration.sideBPlayerIDs.isEmpty else {
            throw SidepotError.invalidRound("Nassau needs players on both sides.")
        }
        if configuration.teamMode == .individual {
            guard configuration.sideAPlayerIDs.count == 1, configuration.sideBPlayerIDs.count == 1 else {
                throw SidepotError.invalidRound("Individual Nassau needs exactly one player per side.")
            }
        }

        var statusLines: [GameStatusLine] = []
        var ledgerEntries: [LedgerEntryValue] = []
        var unresolvedItems: [UnresolvedGameItem] = []
        var metadata: [String: String] = [:]

        for segment in NassauSegment.allCases {
            guard let range = segmentRange(segment, totalHoles: context.holeCount) else { continue }
            let stake = configuration.stake(for: segment)
            guard stake > 0 else { continue }

            let outcome = evaluateSegment(
                segment: segment,
                range: range,
                gameID: gameID,
                context: context,
                configuration: configuration
            )
            statusLines.append(contentsOf: outcome.statusLines)
            ledgerEntries.append(contentsOf: outcome.ledgerEntries)
            unresolvedItems.append(contentsOf: outcome.unresolvedItems)
            metadata.merge(outcome.metadata) { _, new in new }
        }

        return GameEvaluationResult(
            gameID: gameID,
            statusLines: statusLines,
            ledgerEntries: ledgerEntries,
            unresolvedItems: unresolvedItems,
            metadata: metadata
        )
    }

    // MARK: - Segment ranges

    private func segmentRange(_ segment: NassauSegment, totalHoles: Int) -> ClosedRange<Int>? {
        switch segment {
        case .front: return totalHoles >= 9 ? 1...9 : nil
        case .back: return totalHoles >= 18 ? 10...18 : nil
        case .overall: return totalHoles >= 1 ? 1...totalHoles : nil
        }
    }

    // MARK: - Hole outcomes

    private enum HoleOutcome {
        case unresolved
        case decided(MatchSide?)
    }

    private func holeOutcome(
        hole: Int,
        context: RoundEvaluationContext,
        configuration: NassauConfiguration
    ) -> HoleOutcome {
        let aScores = configuration.sideAPlayerIDs.compactMap {
            context.score(for: $0, hole: hole)?.effectiveScore(mode: configuration.scoringMode)
        }
        let bScores = configuration.sideBPlayerIDs.compactMap {
            context.score(for: $0, hole: hole)?.effectiveScore(mode: configuration.scoringMode)
        }
        guard !aScores.isEmpty, !bScores.isEmpty else { return .unresolved }
        return .decided(MatchPlayCalculator.holeWinner(sideAScores: aScores, sideBScores: bScores))
    }

    private func buildResults(
        range: ClosedRange<Int>,
        context: RoundEvaluationContext,
        configuration: NassauConfiguration
    ) -> (results: [HoleResult], unresolvedHoles: [Int]) {
        var results: [HoleResult] = []
        var unresolved: [Int] = []
        for holeNumber in range where holeNumber <= context.throughHole {
            switch holeOutcome(hole: holeNumber, context: context, configuration: configuration) {
            case .unresolved:
                unresolved.append(holeNumber)
            case .decided(let winner):
                results.append(HoleResult(holeNumber: holeNumber, winner: winner))
            }
        }
        return (results, unresolved)
    }

    // MARK: - Segment evaluation

    private struct SegmentOutcome {
        var statusLines: [GameStatusLine] = []
        var ledgerEntries: [LedgerEntryValue] = []
        var unresolvedItems: [UnresolvedGameItem] = []
        var metadata: [String: String] = [:]
    }

    private func evaluateSegment(
        segment: NassauSegment,
        range: ClosedRange<Int>,
        gameID: UUID,
        context: RoundEvaluationContext,
        configuration: NassauConfiguration
    ) -> SegmentOutcome {
        var outcome = SegmentOutcome()

        let (baseResults, baseUnresolvedHoles) = buildResults(range: range, context: context, configuration: configuration)
        for holeNumber in baseUnresolvedHoles {
            outcome.unresolvedItems.append(
                UnresolvedGameItem(description: "\(segment.displayName) Nassau — hole \(holeNumber) missing a score", holeNumber: holeNumber)
            )
        }

        let totalHolesInSegment = range.count
        let baseState = MatchPlayCalculator.evaluate(holeResults: baseResults, totalHolesInSegment: totalHolesInSegment)
        outcome.statusLines.append(statusLine(segment: segment, pressLabel: nil, state: baseState, range: range))

        if isResolved(state: baseState, range: range, throughHole: context.throughHole, hasUnresolvedHoles: !baseUnresolvedHoles.isEmpty) {
            outcome.ledgerEntries.append(contentsOf: teamLedgerEntries(
                state: baseState,
                gameID: gameID,
                segment: segment,
                stake: configuration.stake(for: segment),
                configuration: configuration,
                holeNumber: nil
            ))
        } else if baseUnresolvedHoles.isEmpty {
            outcome.unresolvedItems.append(
                UnresolvedGameItem(description: "\(segment.displayName) Nassau still in progress", holeNumber: nil)
            )
        }

        let derivation = derivePresses(segment: segment, range: range, baseResults: baseResults, configuration: configuration)
        for rejection in derivation.rejectedManual {
            outcome.unresolvedItems.append(
                UnresolvedGameItem(description: "\(segment.displayName) press rejected: \(rejection.reason)", holeNumber: rejection.record.createdAfterHole)
            )
        }

        for press in derivation.presses {
            let pressRange = press.holeRange
            let (pressResults, pressUnresolvedHoles) = buildResults(range: pressRange, context: context, configuration: configuration)
            for holeNumber in pressUnresolvedHoles {
                outcome.unresolvedItems.append(
                    UnresolvedGameItem(
                        description: "\(segment.displayName) press (from hole \(press.createdAfterHole)) — hole \(holeNumber) missing a score",
                        holeNumber: holeNumber
                    )
                )
            }

            let pressState = MatchPlayCalculator.evaluate(holeResults: pressResults, totalHolesInSegment: press.totalHoles)
            outcome.statusLines.append(
                statusLine(segment: segment, pressLabel: "Press from hole \(press.createdAfterHole)", state: pressState, range: pressRange)
            )

            if isResolved(state: pressState, range: pressRange, throughHole: context.throughHole, hasUnresolvedHoles: !pressUnresolvedHoles.isEmpty) {
                outcome.ledgerEntries.append(contentsOf: teamLedgerEntries(
                    state: pressState,
                    gameID: gameID,
                    segment: segment,
                    stake: press.stakeAmount,
                    configuration: configuration,
                    holeNumber: press.createdAfterHole
                ))
            } else if pressUnresolvedHoles.isEmpty {
                outcome.unresolvedItems.append(
                    UnresolvedGameItem(description: "\(segment.displayName) press (from hole \(press.createdAfterHole)) still in progress", holeNumber: nil)
                )
            }
        }

        outcome.metadata["\(segment.rawValue).pressCount"] = "\(derivation.presses.count)"
        return outcome
    }

    private func isResolved(state: MatchState, range: ClosedRange<Int>, throughHole: Int, hasUnresolvedHoles: Bool) -> Bool {
        guard !hasUnresolvedHoles else { return false }
        return state.isClosed || throughHole >= range.upperBound
    }

    private func statusLine(segment: NassauSegment, pressLabel: String?, state: MatchState, range: ClosedRange<Int>) -> GameStatusLine {
        let title = pressLabel.map { "\(segment.displayName) — \($0)" } ?? segment.displayName
        let played = state.holesWonBySideA + state.holesWonBySideB + state.holesHalved
        let detail: String

        if state.isClosed {
            let leaderLabel = state.leader == .a ? "Side A" : "Side B"
            detail = "\(leaderLabel) wins, \(abs(state.differential)) up with \(state.holesRemaining) to play"
        } else if state.holesRemaining == 0 {
            detail = state.differential == 0
                ? "Halved"
                : "\(state.differential > 0 ? "Side A" : "Side B") wins, \(abs(state.differential)) up"
        } else if state.differential == 0 {
            detail = "All square through \(played) of \(range.count)"
        } else {
            let leaderLabel = state.differential > 0 ? "Side A" : "Side B"
            detail = "\(leaderLabel) \(abs(state.differential)) up through \(played) of \(range.count)"
        }

        return GameStatusLine(title: title, detail: detail, holeNumber: nil)
    }

    // MARK: - Ledger

    private func teamLedgerEntries(
        state: MatchState,
        gameID: UUID,
        segment: NassauSegment,
        stake: Decimal,
        configuration: NassauConfiguration,
        holeNumber: Int?
    ) -> [LedgerEntryValue] {
        guard let leader = state.leader else { return [] }

        let winners = configuration.playerIDs(for: leader)
        let losers = configuration.playerIDs(for: leader.opposite)
        guard !winners.isEmpty, !losers.isEmpty, stake > 0 else { return [] }

        let perWinnerShare = MoneySplit.evenSplit(stake, into: winners.count)
        let reason = holeNumber == nil
            ? "\(segment.displayName) Nassau"
            : "\(segment.displayName) press (from hole \(holeNumber!))"

        var entries: [LedgerEntryValue] = []
        for loser in losers {
            for (index, winner) in winners.enumerated() {
                entries.append(
                    LedgerEntryValue(
                        gameID: gameID,
                        holeNumber: holeNumber,
                        segmentName: segment.rawValue,
                        fromPlayerID: loser,
                        toPlayerID: winner,
                        amount: perWinnerShare[index],
                        reason: reason
                    )
                )
            }
        }
        return entries
    }

    // MARK: - Presses

    private struct PressDerivation {
        var presses: [NassauPress] = []
        var rejectedManual: [(record: ManualPressRecord, reason: String)] = []
    }

    private func derivePresses(
        segment: NassauSegment,
        range: ClosedRange<Int>,
        baseResults: [HoleResult],
        configuration: NassauConfiguration
    ) -> PressDerivation {
        var events: [(afterHole: Int, side: MatchSide, trigger: PressTrigger, record: ManualPressRecord?)] = []

        if configuration.autoPressRule == .twoDown {
            var runningA = 0
            var runningB = 0
            var previousDifferential = 0
            for result in baseResults {
                switch result.winner {
                case .a: runningA += 1
                case .b: runningB += 1
                case nil: break
                }
                let differential = runningA - runningB
                if abs(differential) == 2, abs(previousDifferential) != 2, result.holeNumber < range.upperBound {
                    let side: MatchSide = differential > 0 ? .a : .b
                    events.append((afterHole: result.holeNumber, side: side, trigger: .automaticTwoDown, record: nil))
                }
                previousDifferential = differential
            }
        }

        if configuration.allowManualPresses {
            for record in configuration.manualPresses where record.segment == segment {
                events.append((afterHole: record.createdAfterHole, side: record.initiatingSide, trigger: .manual, record: record))
            }
        }

        events.sort { lhs, rhs in
            if lhs.afterHole != rhs.afterHole { return lhs.afterHole < rhs.afterHole }
            return lhs.trigger == .automaticTwoDown && rhs.trigger != .automaticTwoDown
        }

        var derivation = PressDerivation()
        let cap = configuration.maxPressesPerSegment
        let stake = configuration.stake(for: segment) * configuration.pressStakeMultiplier

        for event in events {
            if event.afterHole >= range.upperBound {
                if let record = event.record {
                    derivation.rejectedManual.append((record, "no holes remain in the \(segment.displayName.lowercased()) segment"))
                }
                continue
            }
            if let cap, derivation.presses.count >= cap {
                if let record = event.record {
                    derivation.rejectedManual.append((record, "the segment's press limit (\(cap)) has been reached"))
                }
                continue
            }
            guard let sideID = configuration.sideIdentifier(event.side) else { continue }

            derivation.presses.append(
                NassauPress(
                    segment: segment,
                    createdAfterHole: event.afterHole,
                    startsOnHole: event.afterHole + 1,
                    endsOnHole: range.upperBound,
                    initiatingSideID: sideID,
                    stakeAmount: stake,
                    trigger: event.trigger
                )
            )
        }

        return derivation
    }
}
