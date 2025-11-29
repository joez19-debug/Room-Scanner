import CoreGraphics
import Foundation
import RoomPlan

final class FloorplanBuilder {
    func build(from capturedRoom: CapturedRoom) -> FloorplanModel {
        let walls: [WallSegment2D] = capturedRoom.walls.map { wall in
            let endpoints = projectWallEndpoints(wall)
            return WallSegment2D(
                id: UUID(),
                start: endpoints.start,
                end: endpoints.end,
                thickness: CGFloat(wall.thickness),
                isStructural: wall.category == .structural
            )
        }

        let doorOpenings: [Opening2D] = capturedRoom.doors.map { door in
            Opening2D(
                id: UUID(),
                kind: .door,
                center: projectToPlan(door.transform.columns.3.xyz),
                width: CGFloat(door.dimensions.x),
                wallId: nil
            )
        }

        let windowOpenings: [Opening2D] = capturedRoom.windows.map { window in
            Opening2D(
                id: UUID(),
                kind: .window,
                center: projectToPlan(window.transform.columns.3.xyz),
                width: CGFloat(window.dimensions.x),
                wallId: nil
            )
        }

        let openings = associateOpenings(doorOpenings + windowOpenings, to: walls)

        let furniture: [FurnitureItem2D] = capturedRoom.objects.map { object in
            FurnitureItem2D(
                id: UUID(),
                name: object.category.description,
                category: FurnitureCategory(object.category) ?? .other,
                size: CGSize(width: CGFloat(object.dimensions.x), height: CGFloat(object.dimensions.z)),
                height: CGFloat(object.dimensions.y),
                position: projectToPlan(object.transform.columns.3.xyz),
                rotation: CGFloat(object.transform.eulerAngles.y),
                isLocked: false
            )
        }

        let points = walls.flatMap { [$0.start, $0.end] } + openings.map { $0.center } + furniture.map { $0.position }
        let bounds = FloorplanBuilder.computeBounds(points: points)

        return FloorplanModel(bounds: bounds, walls: walls, openings: openings, furniture: furniture)
    }

    private func projectWallEndpoints(_ wall: CapturedRoom.Wall) -> (start: CGPoint, end: CGPoint) {
        let center = wall.transform.columns.3.xyz
        let lengthAxis = wall.transform.columns.0.xyz
        let horizontalDirection = SIMD3(x: lengthAxis.x, y: 0, z: lengthAxis.z)
        let normalizedDirection = simd_normalize(horizontalDirection)
        let halfLength = wall.length / 2

        let start3D = center - (normalizedDirection * halfLength)
        let end3D = center + (normalizedDirection * halfLength)

        return (projectToPlan(start3D), projectToPlan(end3D))
    }

    private func associateOpenings(_ openings: [Opening2D], to walls: [WallSegment2D]) -> [Opening2D] {
        guard !walls.isEmpty else { return openings }

        return openings.map { opening in
            var nearest = opening
            var bestDistance = CGFloat.greatestFiniteMagnitude

            for wall in walls {
                let distance = distanceFrom(point: opening.center, toLineSegmentStart: wall.start, end: wall.end)
                if distance < bestDistance {
                    bestDistance = distance
                    nearest.wallId = wall.id
                }
            }

            return nearest
        }
    }

    private func distanceFrom(point: CGPoint, toLineSegmentStart start: CGPoint, end: CGPoint) -> CGFloat {
        let line = CGPoint(x: end.x - start.x, y: end.y - start.y)
        let lengthSquared = line.x * line.x + line.y * line.y
        guard lengthSquared > 0 else { return hypot(point.x - start.x, point.y - start.y) }

        let t = max(0, min(1, ((point.x - start.x) * line.x + (point.y - start.y) * line.y) / lengthSquared))
        let projection = CGPoint(x: start.x + t * line.x, y: start.y + t * line.y)
        return hypot(point.x - projection.x, point.y - projection.y)
    }

    private func projectToPlan(_ point: SIMD3<Float>) -> CGPoint {
        CGPoint(x: CGFloat(point.x), y: CGFloat(point.z))
    }

    private static func computeBounds(points: [CGPoint]) -> CGRect {
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
}

private extension CapturedRoom.Object.Category {
    var description: String {
        switch self {
        case .bed: return "Bed"
        case .chair: return "Chair"
        case .sofa: return "Sofa"
        case .table: return "Table"
        case .cabinet: return "Cabinet"
        case .appliance: return "Appliance"
        case .storage: return "Storage"
        @unknown default: return "Object"
        }
    }
}

private extension FurnitureCategory {
    init?(_ category: CapturedRoom.Object.Category) {
        switch category {
        case .bed: self = .bed
        case .chair: self = .chair
        case .sofa: self = .sofa
        case .table: self = .table
        case .cabinet: self = .cabinet
        default: return nil
        }
    }
}

private extension simd_float4 {
    var xyz: SIMD3<Float> {
        SIMD3(x, y, z)
    }
}

private extension simd_float4x4 {
    var eulerAngles: SIMD3<Float> {
        let sy = sqrt(self[0,0] * self[0,0] + self[1,0] * self[1,0])
        let singular = sy < 1e-6

        let x = atan2(self[2,1], self[2,2])
        let y = atan2(-self[2,0], sy)
        let z = singular ? atan2(-self[1,2], self[1,1]) : atan2(self[1,0], self[0,0])
        return SIMD3(x, y, z)
    }
}
