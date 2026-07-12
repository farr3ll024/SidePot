import Foundation

/// Enforces §7's `LedgerEntry` rules and derives balances from a set of entries. Balances are
/// always *derived* from ledger entries — nothing in Sidepot mutates a balance directly (§10,
/// §18: "Balance must be derived, never manually edited").
public enum LedgerValidator {
    /// Throws if any entry violates a hard invariant: positive amount, and no self-payment.
    public static func validate(entries: [LedgerEntryValue]) throws {
        for entry in entries {
            guard entry.amount > 0 else {
                throw SidepotError.nonZeroSumLedger("A ledger entry (\"\(entry.reason)\") has a non-positive amount.")
            }
            guard entry.fromPlayerID != entry.toPlayerID else {
                throw SidepotError.nonZeroSumLedger("A ledger entry (\"\(entry.reason)\") pays a player themselves.")
            }
        }
    }

    /// Folds every entry into a net balance per round-scoped player ID, sorted deterministically.
    /// Recalculating from the same entries always returns the same result (idempotent per §10).
    public static func balances(from entries: [LedgerEntryValue]) -> [PlayerBalance] {
        var totals: [UUID: Decimal] = [:]
        for entry in entries {
            totals[entry.fromPlayerID, default: 0] -= entry.amount
            totals[entry.toPlayerID, default: 0] += entry.amount
        }
        return totals
            .map { PlayerBalance(playerID: $0.key, amount: $0.value) }
            .sorted { $0.playerID.uuidString < $1.playerID.uuidString }
    }

    /// Whether balances sum to exactly zero — the hard precondition for marking a round complete
    /// (§8: "A round must not be marked complete unless sum(all player balances) == 0").
    public static func isZeroSum(_ balances: [PlayerBalance]) -> Bool {
        balances.reduce(Decimal(0)) { $0 + $1.amount } == 0
    }
}
