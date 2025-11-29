import Combine
import Foundation
import SwiftUI

final class ProjectStore: ObservableObject {
    @Published var projects: [RoomProject]

    init(projects: [RoomProject] = ProjectStore.sampleProjects) {
        self.projects = projects
    }
}

// MARK: - Sample Data
extension ProjectStore {
    private static var sampleProjects: [RoomProject] {
        let now = Date()
        return [
            RoomProject(
                id: UUID(),
                name: "Living Room",
                createdAt: now.addingTimeInterval(-3600),
                updatedAt: now.addingTimeInterval(-1800),
                usdzFileURL: URL(filePath: "/tmp/living-room.usdz"),
                floorplanJSONURL: nil,
                notes: "Sample project for previews"
            ),
            RoomProject(
                id: UUID(),
                name: "Studio",
                createdAt: now.addingTimeInterval(-7200),
                updatedAt: now.addingTimeInterval(-3600),
                usdzFileURL: URL(filePath: "/tmp/studio.usdz"),
                floorplanJSONURL: nil,
                notes: nil
            )
        ]
    }
}
