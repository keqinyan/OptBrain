import Foundation
import SwiftData

final class PersistenceController {
    static let shared = PersistenceController()

    let container: ModelContainer

    private init() {
        let schema = Schema([Session.self, Trial.self])
        let config = ModelConfiguration("OptBrain", schema: schema)
        do {
            self.container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Unable to create ModelContainer: \(error)")
        }
    }

    @MainActor
    func wipeAll() throws {
        let context = container.mainContext
        try context.delete(model: Trial.self)
        try context.delete(model: Session.self)
        try context.save()
    }
}
