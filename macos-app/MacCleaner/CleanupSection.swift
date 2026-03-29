import Foundation
import SwiftUI

enum SectionStatus {
    case idle, running, done, failed
}

struct CleanupResult {
    let freedBytes: Int64
    let message: String
    let details: [String]
}

@MainActor
class CleanupSection: ObservableObject, Identifiable {
    let id: String
    let icon: String
    let title: String
    let description: String

    @Published var status: SectionStatus = .idle
    @Published var result: CleanupResult?
    @Published var progress: Double = 0

    private let action: () async throws -> CleanupResult

    init(id: String, icon: String, title: String, description: String,
         action: @escaping () async throws -> CleanupResult) {
        self.id = id
        self.icon = icon
        self.title = title
        self.description = description
        self.action = action
    }

    func run() async {
        status = .running
        progress = 0
        result = nil
        do {
            result = try await action()
            status = .done
            progress = 1
        } catch {
            result = CleanupResult(freedBytes: 0,
                                   message: error.localizedDescription,
                                   details: [])
            status = .failed
            progress = 1
        }
    }
}
