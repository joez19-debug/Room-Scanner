import Foundation
import RoomPlan
import CoreGraphics

/// Converts a `CapturedRoom` from RoomPlan into an app-specific `FloorplanModel`.
final class FloorplanBuilder {
    /// Builds a simple 2D floorplan projection from a captured room.
    /// - Parameter capturedRoom: The room returned by RoomPlan.
    /// - Returns: A `FloorplanModel` containing projected walls, openings, and furniture.
    func build(from capturedRoom: CapturedRoom) -> FloorplanModel {
        let wallSurfaces = capturedRoom.surfaces.filter { surface in
            String(describing: surface.category).lowercased() == "wall"
        }
        let openingSurfaces = capturedRoom.surfaces.filter { surface in
            let name = String(describing: surface.category).lowercased()
            return name.contains("door") || name.contains("window") || name.contains("opening")
        }

        let walls = buildWalls(from: wallSurfaces)
        let openings = buildOpenings(from: openingSurfaces, walls: walls)
        let furniture = buildFurniture(from: capturedRoom.objects)

        let allPoints: [CGPoint] = walls.flatMap { [$0.start, $0.end] } + openings.map { $0.center } + furniture.map { $0.position }
        let bounds = boundingBox(for: allPoints)

        return FloorplanModel(bounds: bounds, walls: walls, openings: openings, furniture: furniture)
    }

    // MARK: - Helpers

    private func buildWalls(from walls: [CapturedRoom.Surface]) -> [WallSegment2D] {
        walls.compactMap { wall in
            let points = wall.curve.points
            guard let first = points.first, let last = points.last else { return nil }
            let start = projectToPlan(first)
            let end = projectToPlan(last)

            return WallSegment2D(
                id: wall.identifier,
                start: start,
                end: end,
                thickness: CGFloat(wall.thickness),
                isStructural: true
            )
        }
    }

    private func buildOpenings(from openings: [CapturedRoom.Surface], walls: [WallSegment2D]) -> [Opening2D] {
        openings.map { opening in
            let center = projectToPlan(opening.transform.columns.3)
            let width = CGFloat(opening.dimensions.x)
            let nearestWallId = nearestWall(for: center, in: walls)?.id
            let kind: OpeningKind
            let categoryName = String(describing: opening.category).lowercased()
            if categoryName.contains("door") {
                kind = .door
            } else if categoryName.contains("window") {
                kind = .window
            } else {
                kind = .opening
            }

            return Opening2D(
                id: opening.identifier,
                kind: kind,
                center: center,
                width: width,
                wallId: nearestWallId
            )
        }
    }

    private func buildFurniture(from objects: [CapturedRoom.Object]) -> [FurnitureItem2D] {
        objects.map { object in
            let center = projectToPlan(object.transform.columns.3)
            let size = CGSize(width: CGFloat(object.dimensions.x), height: CGFloat(object.dimensions.z))
            let category = mapCategory(object.category)
            let rotation = atan2(CGFloat(object.transform.columns.0.z), CGFloat(object.transform.columns.0.x))

            return FurnitureItem2D(
                id: object.identifier,
                name: String(describing: object.category).capitalized,
                category: category,
                size: size,
                height: CGFloat(object.dimensions.y),
                position: center,
                rotation: rotation,
                isLocked: true
            )
        }
    }

    private func mapCategory(_ category: CapturedRoom.Object.Category) -> FurnitureCategory {
        switch category {
        case .bed: return .bed
        case .sofa: return .sofa
        case .chair: return .chair
        case .table: return .table
        default: return .other
        }
    }

    private func projectToPlan(_ vector: SIMD3<Float>) -> CGPoint {
        CGPoint(x: CGFloat(vector.x), y: CGFloat(vector.z))
    }

    private func projectToPlan(_ column: SIMD4<Float>) -> CGPoint {
        CGPoint(x: CGFloat(column.x), y: CGFloat(column.z))
    }

    private func boundingBox(for points: [CGPoint]) -> CGRect {
        guard let first = points.first else { return .zero }
        var minX = first.x
        var maxX = first.x
        var minY = first.y
        var maxY = first.y

        for point in points.dropFirst() {
            minX = min(minX, point.x)
            maxX = max(maxX, point.x)
            minY = min(minY, point.y)
            maxY = max(maxY, point.y)
        }

        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    private func nearestWall(for point: CGPoint, in walls: [WallSegment2D]) -> WallSegment2D? {
        guard !walls.isEmpty else { return nil }
        var nearest: WallSegment2D?
        var bestDistance = CGFloat.greatestFiniteMagnitude

        for wall in walls {
            let distance = distanceFrom(point, toSegment: (wall.start, wall.end))
            if distance < bestDistance {
                bestDistance = distance
                nearest = wall
            }
        }
        return nearest
    }

    private func distanceFrom(_ point: CGPoint, toSegment segment: (CGPoint, CGPoint)) -> CGFloat {
        let (a, b) = segment
        let ab = CGPoint(x: b.x - a.x, y: b.y - a.y)
        let ap = CGPoint(x: point.x - a.x, y: point.y - a.y)
        let abLengthSquared = ab.x * ab.x + ab.y * ab.y
        guard abLengthSquared > 0 else { return hypot(ap.x, ap.y) }
        let t = max(0, min(1, (ap.x * ab.x + ap.y * ab.y) / abLengthSquared))
        let projection = CGPoint(x: a.x + t * ab.x, y: a.y + t * ab.y)
        return hypot(point.x - projection.x, point.y - projection.y)
    }
}
