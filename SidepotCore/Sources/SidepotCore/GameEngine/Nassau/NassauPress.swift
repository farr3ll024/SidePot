import Foundation

public enum PressTrigger: Codable, Equatable, Sendable {
    case automaticTwoDown
    case manual
}

/// An independent match spawned within a Nassau segment, either automatically (two-down) or by a
/// manual user action (§12). Presses always start on the hole after they're created and end at
/// their segment's boundary.
public struct NassauPress: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public let segment: NassauSegment
    public let createdAfterHole: Int
    public let startsOnHole: Int
    public let endsOnHole: Int
    public let initiatingSideID: UUID
    public let stakeAmount: Decimal
    public let trigger: PressTrigger

    public init(
        id: UUID = UUID(),
        segment: NassauSegment,
        createdAfterHole: Int,
        startsOnHole: Int,
        endsOnHole: Int,
        initiatingSideID: UUID,
        stakeAmount: Decimal,
        trigger: PressTrigger
    ) {
        self.id = id
        self.segment = segment
        self.createdAfterHole = createdAfterHole
        self.startsOnHole = startsOnHole
        self.endsOnHole = endsOnHole
        self.initiatingSideID = initiatingSideID
        self.stakeAmount = stakeAmount
        self.trigger = trigger
    }

    var holeRange: ClosedRange<Int> { startsOnHole...endsOnHole }
    var totalHoles: Int { endsOnHole - startsOnHole + 1 }
}
