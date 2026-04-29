import Foundation
#if canImport(HealthKit)
import HealthKit
#endif

/// Optional HealthKit shell. The app must function without it.
/// Add the HealthKit capability and an NSHealthShareUsageDescription in Info.plist before
/// enabling permission requests at runtime.
final class HealthKitService {
    static let shared = HealthKitService()

    #if canImport(HealthKit)
    private let store = HKHealthStore()
    #endif

    var isAvailable: Bool {
        #if canImport(HealthKit)
        return HKHealthStore.isHealthDataAvailable()
        #else
        return false
        #endif
    }

    /// Read-only types we may request: sleep, steps, resting HR, HRV.
    func requestAuthorization() async throws {
        #if canImport(HealthKit)
        guard isAvailable else { return }
        var read: Set<HKObjectType> = []
        if let t = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) { read.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .stepCount) { read.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .restingHeartRate) { read.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) { read.insert(t) }
        try await store.requestAuthorization(toShare: [], read: read)
        #endif
    }

    // MARK: - Read accessors (stubs - implement when HealthKit is wired up)

    func sleepDurationHours(on day: Date) async -> Double? { nil }
    func steps(on day: Date) async -> Int? { nil }
    func restingHeartRate(on day: Date) async -> Double? { nil }
    func hrv(on day: Date) async -> Double? { nil }
}
