import CoreGraphics
import Foundation

struct FloorplanModel: Codable, Equatable {
    var bounds: CGRect
    var walls: [WallSegment2D]
    var openings: [Opening2D]
    var furniture: [FurnitureItem2D]
}

struct WallSegment2D: Identifiable, Codable, Equatable {
    let id: UUID
    var start: CGPoint
    var end: CGPoint
    var thickness: CGFloat
    var isStructural: Bool
}

enum OpeningKind: String, Codable {
    case door
    case window
    case opening
}

struct Opening2D: Identifiable, Codable, Equatable {
    let id: UUID
    var kind: OpeningKind
    var center: CGPoint
    var width: CGFloat
    var wallId: UUID?
}

enum FurnitureCategory: String, Codable {
    case bed, sofa, chair, table, cabinet, desk, other
}

struct FurnitureItem2D: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var category: FurnitureCategory
    var size: CGSize
    var height: CGFloat
    var position: CGPoint
    var rotation: CGFloat
    var isLocked: Bool
}
