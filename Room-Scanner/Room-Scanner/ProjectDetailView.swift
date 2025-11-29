import SwiftUI
import CoreGraphics

struct ProjectDetailView: View {
    let project: RoomProject

    private var demoFloorplan: FloorplanModel {
        let wall1 = WallSegment2D(id: UUID(), start: CGPoint(x: -2, y: -2), end: CGPoint(x: 2, y: -2), thickness: 0.1, isStructural: true)
        let wall2 = WallSegment2D(id: UUID(), start: CGPoint(x: 2, y: -2), end: CGPoint(x: 2, y: 2), thickness: 0.1, isStructural: true)
        let wall3 = WallSegment2D(id: UUID(), start: CGPoint(x: 2, y: 2), end: CGPoint(x: -2, y: 2), thickness: 0.1, isStructural: true)
        let wall4 = WallSegment2D(id: UUID(), start: CGPoint(x: -2, y: 2), end: CGPoint(x: -2, y: -2), thickness: 0.1, isStructural: true)

        let opening = Opening2D(id: UUID(), kind: .door, center: CGPoint(x: 0, y: -2), width: 0.9, wallId: wall1.id)
        let furniture = FurnitureItem2D(id: UUID(), name: "Sofa", category: .sofa, size: CGSize(width: 1.6, height: 0.8), height: 0.9, position: CGPoint(x: 0, y: 0), rotation: 0, isLocked: false)

        return FloorplanModel(
            bounds: CGRect(x: -2.5, y: -2.5, width: 5, height: 5),
            walls: [wall1, wall2, wall3, wall4],
            openings: [opening],
            furniture: [furniture]
        )
    }

    var body: some View {
        TabView {
            FloorplanView(model: demoFloorplan)
                .tabItem {
                    Label("2D Plan", systemImage: "square.grid.2x2")
                }

            Room3DContainerView(project: project)
                .tabItem {
                    Label("3D View", systemImage: "cube")
                }
        }
        .navigationTitle(project.name)
    }
}

#Preview {
    ProjectDetailView(
        project: RoomProject(
            id: UUID(),
            name: "Sample Project",
            createdAt: .now,
            updatedAt: .now,
            usdzFileURL: URL(filePath: "/tmp/sample.usdz"),
            floorplanJSONURL: nil,
            notes: nil
        )
    )
}
