import Foundation

/// Individual skins with optional carryovers (§11). Evaluates every hole from 1 through
/// `context.throughHole`, resolving skins hole by hole and tracking the current carry count.
public struct SkinsEvaluator: GolfGameEvaluating {
    public init() {}

    public func evaluate(
        gameID: UUID,
        context: RoundEvaluationContext,
        configuration: SkinsConfiguration
    ) throws -> GameEvaluationResult {
        let participants = configuration.participantIDs.sorted { $0.uuidString < $1.uuidString }
        guard participants.count >= 2 else {
            return GameEvaluationResult(gameID: gameID, statusLines: [], ledgerEntries: [], unresolvedItems: [])
        }

        var carry = 1
        var totalSkinsAwarded = 0
        var skinsByPlayer: [UUID: Int] = [:]
        var biggestSkin: (holeNumber: Int, playerID: UUID, amount: Decimal)?
        var ledgerEntries: [LedgerEntryValue] = []
        var statusLines: [GameStatusLine] = []
        var unresolvedItems: [UnresolvedGameItem] = []

        let holesInPlay = context.orderedHoles.filter { $0.number <= context.throughHole }

        for hole in holesInPlay {
            let holeScores = context.scores(forHole: hole.number)
                .filter { participants.contains($0.roundPlayerID) }
            let eligible = holeScores.filter(\.isEntered)

            guard eligible.count == participants.count || !configuration.requireAllScoresBeforeResolving else {
                unresolvedItems.append(
                    UnresolvedGameItem(description: "Hole \(hole.number) skin — waiting on scores", holeNumber: hole.number)
                )
                continue
            }
            guard !eligible.isEmpty else { continue }

            let scored: [(playerID: UUID, value: Int)] = eligible.compactMap { score in
                guard let value = score.effectiveScore(mode: configuration.scoringMode) else { return nil }
                return (score.roundPlayerID, value)
            }
            guard let minValue = scored.map(\.value).min() else { continue }
            let lowPlayers = scored.filter { $0.value == minValue }.map(\.playerID)

            if lowPlayers.count == 1, let winner = lowPlayers.first {
                let skinsValue = carry
                let holeAmount = configuration.baseAmount * Decimal(skinsValue)
                let losers = participants.filter { $0 != winner }

                switch configuration.stakeMode {
                case .fixedValuePerSkin:
                    for loser in losers {
                        ledgerEntries.append(
                            LedgerEntryValue(
                                gameID: gameID,
                                holeNumber: hole.number,
                                segmentName: nil,
                                fromPlayerID: loser,
                                toPlayerID: winner,
                                amount: configuration.baseAmount * Decimal(skinsValue),
                                reason: skinsValue > 1 ? "Skin (×\(skinsValue) carry) — hole \(hole.number)" : "Skin — hole \(hole.number)"
                            )
                        )
                    }
                case .potPerHole:
                    let anteShares = MoneySplit.evenSplit(configuration.baseAmount * Decimal(skinsValue), into: participants.count)
                    for loser in losers {
                        let loserIndex = participants.firstIndex(of: loser) ?? 0
                        ledgerEntries.append(
                            LedgerEntryValue(
                                gameID: gameID,
                                holeNumber: hole.number,
                                segmentName: nil,
                                fromPlayerID: loser,
                                toPlayerID: winner,
                                amount: anteShares[loserIndex],
                                reason: skinsValue > 1 ? "Skin pot (×\(skinsValue) carry) — hole \(hole.number)" : "Skin pot — hole \(hole.number)"
                            )
                        )
                    }
                }

                skinsByPlayer[winner, default: 0] += skinsValue
                totalSkinsAwarded += skinsValue
                if biggestSkin == nil || holeAmount > biggestSkin!.amount {
                    biggestSkin = (hole.number, winner, holeAmount)
                }
                statusLines.append(
                    GameStatusLine(
                        title: "Hole \(hole.number)",
                        detail: "\(skinsValue) skin\(skinsValue == 1 ? "" : "s") won",
                        holeNumber: hole.number
                    )
                )
                carry = 1
            } else {
                if configuration.tiesCarry && configuration.carryoversEnabled {
                    let cap = configuration.carryoverCap
                    if cap == nil || carry < cap! {
                        carry += 1
                    }
                    statusLines.append(
                        GameStatusLine(title: "Hole \(hole.number)", detail: "Tied — carries to \(carry)", holeNumber: hole.number)
                    )
                } else {
                    statusLines.append(
                        GameStatusLine(title: "Hole \(hole.number)", detail: "Tied — no skin awarded", holeNumber: hole.number)
                    )
                    carry = 1
                }
            }
        }

        var metadata: [String: String] = ["totalSkinsAwarded": "\(totalSkinsAwarded)"]
        if carry > 1 {
            metadata["currentCarry"] = "\(carry)"
        }
        if let biggestSkin {
            metadata["biggestSkinHole"] = "\(biggestSkin.holeNumber)"
            metadata["biggestSkinPlayerID"] = biggestSkin.playerID.uuidString
            metadata["biggestSkinAmount"] = NSDecimalNumber(decimal: biggestSkin.amount).stringValue
        }
        for (playerID, count) in skinsByPlayer {
            metadata["skinsWon.\(playerID.uuidString)"] = "\(count)"
        }

        return GameEvaluationResult(
            gameID: gameID,
            statusLines: statusLines,
            ledgerEntries: ledgerEntries,
            unresolvedItems: unresolvedItems,
            metadata: metadata
        )
    }
}
