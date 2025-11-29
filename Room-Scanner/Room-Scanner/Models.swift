import Foundation
import CoreGraphics

// MARK: - Core Entities

/// Project-level metadata and asset references for a scanned room.
struct RoomProject: Identifiable, Codable {
    let id: UUID
    var name: String
    var createdAt: Date
    var updatedAt: Date

    /// Relative or absolute paths to persisted assets
    var usdzFileURL: URL
    var floorplanJSONURL: URL?

    /// Optional metadata
    var notes: String?
}

/// A 2D representation of a captured floorplan with projected geometry.
struct FloorplanModel: Codable {
    var bounds: CGRect              // overall plan bbox in plan coordinates
    var walls: [WallSegment2D]
    var openings: [Opening2D]       // doors, windows
    var furniture: [FurnitureItem2D]
}

/// A straight wall segment expressed in plan coordinates.
struct WallSegment2D: Identifiable, Codable {
    let id: UUID
    var start: CGPoint              // in plan coordinate system
    var end: CGPoint
    var thickness: CGFloat
    var isStructural: Bool
}

/// The type of opening found along a wall.
enum OpeningKind: String, Codable {
    case door
    case window
    case opening
}

/// A projected opening (door/window) in 2D space.
struct Opening2D: Identifiable, Codable {
    let id: UUID
    var kind: OpeningKind
    var center: CGPoint
    var width: CGFloat
    var wallId: UUID?              // optional association to wall
}

/// Furniture category mapped from RoomPlan objects.
enum FurnitureCategory: String, Codable {
    case bed, sofa, chair, table, cabinet, desk, other
}

/// A furniture footprint placed within the 2D plan.
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
