import Foundation

/// Sand-save bets, entirely driven by manual entries (§15). Each qualifying entry is an
/// independent event — there's no notion of a hole being "unresolved" the way skins or greenies
/// are, since a sandie only exists once the organizer records one.
public struct SandiesEvaluator: GolfGameEvaluating {
    public init() {}

    public func evaluate(
        gameID: UUID,
        context: RoundEvaluationContext,
        configuration: SandiesConfiguration
    ) throws -> GameEvaluationResult {
        let participants = Set(configuration.participantIDs)
        guard participants.count >= 2 else {
            return GameEvaluationResult(gameID: gameID, statusLines: [], ledgerEntries: [], unresolvedItems: [])
        }

        var statusLines: [GameStatusLine] = []
        var ledgerEntries: [LedgerEntryValue] = []

        for entry in configuration.entries
        where entry.holeNumber <= context.throughHole
            && entry.madeParOrBetter
            && participants.contains(entry.roundPlayerID) {
            let opponents = participants.filter { $0 != entry.roundPlayerID }
            guard !opponents.isEmpty else { continue }
            for opponent in opponents {
                ledgerEntries.append(
                    LedgerEntryValue(
                        gameID: gameID,
                        holeNumber: entry.holeNumber,
                        segmentName: nil,
                        fromPlayerID: opponent,
                        toPlayerID: entry.roundPlayerID,
                        amount: configuration.amount,
                        reason: "Sandie — hole \(entry.holeNumber)"
                    )
                )
            }
            statusLines.append(GameStatusLine(title: "Hole \(entry.holeNumber)", detail: "Sandie made", holeNumber: entry.holeNumber))
        }

        return GameEvaluationResult(gameID: gameID, statusLines: statusLines, ledgerEntries: ledgerEntries, unresolvedItems: [])
    }
}
