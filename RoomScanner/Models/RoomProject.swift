import Foundation

struct RoomProject: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var createdAt: Date
    var updatedAt: Date

    var usdzFileURL: URL
    var floorplanJSONURL: URL?

    var notes: String?
}
