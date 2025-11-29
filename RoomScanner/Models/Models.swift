import Foundation
import CoreGraphics

/// Project metadata and references to persisted assets.
struct RoomProject: Identifiable, Codable {
    let id: UUID
    var name: String
    var createdAt: Date
    var updatedAt: Date

    /// Relative or absolute paths to persisted assets.
    var usdzFileURL: URL
    var floorplanJSONURL: URL?

    /// Optional metadata.
    var notes: String?
}

/// Top-down 2D representation of a captured space.
struct FloorplanModel: Codable {
    var bounds: CGRect              // overall plan bbox in plan coordinates
    var walls: [WallSegment2D]
    var openings: [Opening2D]       // doors, windows
    var furniture: [FurnitureItem2D]
}

/// A straight wall segment in the plan coordinate system.
struct WallSegment2D: Identifiable, Codable {
    let id: UUID
    var start: CGPoint              // in plan coordinate system
    var end: CGPoint
    var thickness: CGFloat
    var isStructural: Bool
}

enum OpeningKind: String, Codable {
    case door
    case window
    case opening
}

/// Door, window, or other opening associated with a wall.
struct Opening2D: Identifiable, Codable {
    let id: UUID
    var kind: OpeningKind
    var center: CGPoint
    var width: CGFloat
    var wallId: UUID?              // optional association to wall
}

enum FurnitureCategory: String, Codable {
    case bed, sofa, chair, table, cabinet, desk, other
}

/// Lightweight furniture record positioned in plan space.
struct FurnitureItem2D: Identifiable, Codable {
    let id: UUID
    var name: String
    var category: FurnitureCategory
    var size: CGSize                // width/depth in plan plane
    var height: CGFloat
    var position: CGPoint           // center in plan coordinates
    var rotation: CGFloat           // radians
    var isLocked: Bool
}
