import Foundation
import SwiftData

/// A per-round snapshot of the course being played. v1 intentionally has no global course
/// database — every round records its own copy of the holes it was played on (§7).
@Model
public final class CourseSnapshot {
    public var id: UUID = UUID()
    public var name: String = ""
    public var teeName: String?
    public var holeCount: Int = 18

    @Relationship(deleteRule: .cascade, inverse: \HoleSnapshot.course)
    public var holes: [HoleSnapshot]? = []

    public var round: GolfRound?

    public init(
        id: UUID = UUID(),
        name: String,
        teeName: String? = nil,
        holeCount: Int = 18,
        holes: [HoleSnapshot] = []
    ) {
        self.id = id
        self.name = name
        self.teeName = teeName
        self.holeCount = holeCount
        self.holes = holes
    }

    public var orderedHoles: [HoleSnapshot] {
        (holes ?? []).sorted { $0.number < $1.number }
    }

    public func validate() throws {
        if name.trimmingCharacters(in: .whitespaces).isEmpty {
            throw SidepotError.invalidRound("A course needs a name.")
        }
        guard holeCount == 9 || holeCount == 18 else {
            throw SidepotError.invalidRound("Rounds are 9 or 18 holes.")
        }
        for hole in holes ?? [] {
            try hole.validate()
        }
    }
}
