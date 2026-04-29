import Foundation
import SwiftData

@Model
final class Trial {
    var trialIndex: Int
    var responseTimeMs: Double?    // nil for missed/no-response trials
    var isCorrect: Bool
    var isFalseStart: Bool
    var isMissed: Bool

    // Stroop-specific: was the word/color pair congruent?
    var stroopCongruent: Bool?
    // Number Order-specific: grid size N (square grid is N x N).
    var gridSize: Int?

    var session: Session?

    init(
        trialIndex: Int,
        responseTimeMs: Double? = nil,
        isCorrect: Bool = true,
        isFalseStart: Bool = false,
        isMissed: Bool = false,
        stroopCongruent: Bool? = nil,
        gridSize: Int? = nil
    ) {
        self.trialIndex = trialIndex
        self.responseTimeMs = responseTimeMs
        self.isCorrect = isCorrect
        self.isFalseStart = isFalseStart
        self.isMissed = isMissed
        self.stroopCongruent = stroopCongruent
        self.gridSize = gridSize
    }
}
