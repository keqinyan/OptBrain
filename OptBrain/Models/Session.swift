import Foundation
import SwiftData

@Model
final class Session {
    @Attribute(.unique) var sessionId: UUID
    var testTypeRaw: String
    var startTime: Date
    var endTime: Date
    var localeIdentifier: String

    // Summary metrics computed at session close.
    var meanResponseTimeMs: Double?    // ms; nil if not applicable
    var accuracy: Double?              // 0...1; nil if not applicable
    var stabilityCV: Double?           // coefficient of variation of RTs
    var mistakeCount: Int
    var completionTimeMs: Double?      // for tasks with a single duration (number order)
    var fatigueDelta: Double?          // (secondHalfMean - firstHalfMean) / firstHalfMean

    @Relationship(deleteRule: .cascade, inverse: \Trial.session)
    var trials: [Trial] = []

    init(
        sessionId: UUID = UUID(),
        testType: TestType,
        startTime: Date,
        endTime: Date,
        localeIdentifier: String = Locale.current.identifier,
        meanResponseTimeMs: Double? = nil,
        accuracy: Double? = nil,
        stabilityCV: Double? = nil,
        mistakeCount: Int = 0,
        completionTimeMs: Double? = nil,
        fatigueDelta: Double? = nil
    ) {
        self.sessionId = sessionId
        self.testTypeRaw = testType.rawValue
        self.startTime = startTime
        self.endTime = endTime
        self.localeIdentifier = localeIdentifier
        self.meanResponseTimeMs = meanResponseTimeMs
        self.accuracy = accuracy
        self.stabilityCV = stabilityCV
        self.mistakeCount = mistakeCount
        self.completionTimeMs = completionTimeMs
        self.fatigueDelta = fatigueDelta
    }

    var testType: TestType {
        TestType(rawValue: testTypeRaw) ?? .reactionTime
    }

    var timeOfDay: TimeOfDay {
        TimeOfDay.bucket(for: startTime)
    }
}
