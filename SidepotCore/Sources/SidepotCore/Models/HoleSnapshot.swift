import Foundation
import SwiftData

/// A single hole's par/stroke-index/yardage as entered for one specific round. Never shared across
/// rounds — see `CourseSnapshot`.
@Model
public final class HoleSnapshot {
    public var id: UUID = UUID()
    public var number: Int = 1
    public var par: Int = 4
    public var strokeIndex: Int?
    public var yardage: Int?

    public var course: CourseSnapshot?

    public init(
        id: UUID = UUID(),
        number: Int,
        par: Int,
        strokeIndex: Int? = nil,
        yardage: Int? = nil
    ) {
        self.id = id
        self.number = number
        self.par = par
        self.strokeIndex = strokeIndex
        self.yardage = yardage
    }

    public func validate() throws {
        guard (1...18).contains(number) else {
            throw SidepotError.invalidRound("Hole number must be between 1 and 18.")
        }
        guard (3...6).contains(par) else {
            throw SidepotError.invalidRound("Par must be between 3 and 6.")
        }
        if let strokeIndex, !(1...18).contains(strokeIndex) {
            throw SidepotError.invalidRound("Stroke index must be between 1 and 18.")
        }
    }

    public var asValue: HoleSnapshotValue {
        HoleSnapshotValue(id: id, number: number, par: par, strokeIndex: strokeIndex, yardage: yardage)
    }
}
