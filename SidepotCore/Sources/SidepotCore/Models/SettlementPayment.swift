import Foundation
import SwiftData

/// One optimized payment from the settlement engine (§17), plus whether the user has marked it
/// paid outside the app (Sidepot never moves money itself).
@Model
public final class SettlementPayment {
    public var id: UUID = UUID()
    public var fromPlayerID: UUID = UUID()
    public var toPlayerID: UUID = UUID()
    public var amount: Decimal = 0
    public var isMarkedPaid: Bool = false
    public var markedPaidAt: Date?

    public var round: GolfRound?

    public init(
        id: UUID = UUID(),
        fromPlayerID: UUID,
        toPlayerID: UUID,
        amount: Decimal,
        isMarkedPaid: Bool = false,
        markedPaidAt: Date? = nil
    ) {
        self.id = id
        self.fromPlayerID = fromPlayerID
        self.toPlayerID = toPlayerID
        self.amount = amount
        self.isMarkedPaid = isMarkedPaid
        self.markedPaidAt = markedPaidAt
    }

    public convenience init(value: SettlementPaymentValue) {
        self.init(
            id: value.id,
            fromPlayerID: value.fromPlayerID,
            toPlayerID: value.toPlayerID,
            amount: value.amount
        )
    }
}
