import Foundation

/// Exports session + trial data as CSV or JSON.
/// Returns a temporary file URL the caller can hand to a ShareSheet.
struct ExportService {
    enum Format { case csv, json }

    static func export(sessions: [Session], format: Format) throws -> URL {
        let dir = FileManager.default.temporaryDirectory
        let timestamp = ISO8601DateFormatter().string(from: .now).replacingOccurrences(of: ":", with: "-")
        let url = dir.appendingPathComponent("OptBrain-\(timestamp).\(format == .csv ? "csv" : "json")")

        switch format {
        case .csv:
            try makeCSV(sessions: sessions).write(to: url, atomically: true, encoding: .utf8)
        case .json:
            try makeJSON(sessions: sessions).write(to: url, options: .atomic)
        }
        return url
    }

    private static func makeCSV(sessions: [Session]) -> String {
        var lines: [String] = []
        lines.append([
            "session_id","test_type","start_time","end_time","locale",
            "mean_rt_ms","accuracy","stability_cv","mistake_count",
            "completion_time_ms","fatigue_delta",
            "trial_index","trial_rt_ms","trial_correct","false_start","missed",
            "stroop_congruent","grid_size"
        ].joined(separator: ","))

        let iso = ISO8601DateFormatter()
        for s in sessions {
            let common = [
                s.sessionId.uuidString,
                s.testTypeRaw,
                iso.string(from: s.startTime),
                iso.string(from: s.endTime),
                s.localeIdentifier,
                fmt(s.meanResponseTimeMs),
                fmt(s.accuracy),
                fmt(s.stabilityCV),
                "\(s.mistakeCount)",
                fmt(s.completionTimeMs),
                fmt(s.fatigueDelta),
            ]
            if s.trials.isEmpty {
                lines.append((common + ["","","","","","",""]).joined(separator: ","))
            } else {
                for t in s.trials.sorted(by: { $0.trialIndex < $1.trialIndex }) {
                    lines.append((common + [
                        "\(t.trialIndex)",
                        fmt(t.responseTimeMs),
                        t.isCorrect ? "1" : "0",
                        t.isFalseStart ? "1" : "0",
                        t.isMissed ? "1" : "0",
                        t.stroopCongruent.map { $0 ? "1" : "0" } ?? "",
                        t.gridSize.map(String.init) ?? "",
                    ]).joined(separator: ","))
                }
            }
        }
        return lines.joined(separator: "\n")
    }

    private static func makeJSON(sessions: [Session]) throws -> Data {
        struct TrialDTO: Codable {
            var trialIndex: Int
            var responseTimeMs: Double?
            var isCorrect: Bool
            var isFalseStart: Bool
            var isMissed: Bool
            var stroopCongruent: Bool?
            var gridSize: Int?
        }
        struct SessionDTO: Codable {
            var sessionId: String
            var testType: String
            var startTime: Date
            var endTime: Date
            var locale: String
            var meanResponseTimeMs: Double?
            var accuracy: Double?
            var stabilityCV: Double?
            var mistakeCount: Int
            var completionTimeMs: Double?
            var fatigueDelta: Double?
            var trials: [TrialDTO]
        }

        let dtos = sessions.map { s in
            SessionDTO(
                sessionId: s.sessionId.uuidString,
                testType: s.testTypeRaw,
                startTime: s.startTime,
                endTime: s.endTime,
                locale: s.localeIdentifier,
                meanResponseTimeMs: s.meanResponseTimeMs,
                accuracy: s.accuracy,
                stabilityCV: s.stabilityCV,
                mistakeCount: s.mistakeCount,
                completionTimeMs: s.completionTimeMs,
                fatigueDelta: s.fatigueDelta,
                trials: s.trials.sorted(by: { $0.trialIndex < $1.trialIndex }).map {
                    TrialDTO(
                        trialIndex: $0.trialIndex,
                        responseTimeMs: $0.responseTimeMs,
                        isCorrect: $0.isCorrect,
                        isFalseStart: $0.isFalseStart,
                        isMissed: $0.isMissed,
                        stroopCongruent: $0.stroopCongruent,
                        gridSize: $0.gridSize
                    )
                }
            )
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(dtos)
    }

    private static func fmt(_ value: Double?) -> String {
        guard let v = value else { return "" }
        return String(format: "%.4f", v)
    }
}
