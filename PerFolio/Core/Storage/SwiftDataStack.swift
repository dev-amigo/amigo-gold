import Foundation
import SwiftData

@available(iOS 17.0, *)
@MainActor
final class SwiftDataStack {
    let container: ModelContainer

    init() {
        let schema = Schema([
            AGUserProfile.self,
        ])

        do {
            container = try ModelContainer(for: schema)
        } catch {
            fatalError("Failed to bootstrap SwiftData \(error.localizedDescription)")
        }
    }
}
