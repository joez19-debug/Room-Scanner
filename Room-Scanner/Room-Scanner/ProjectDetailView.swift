import SwiftUI
import CoreGraphics
import Foundation

struct ProjectDetailView: View {
    let project: RoomProject
    @State private var floorplan: FloorplanModel?
    @State private var floorplanError: String?

    var body: some View {
        TabView {
            floorplanTab

            Room3DContainerView(project: project)
                .tabItem {
                    Label("3D View", systemImage: "cube")
                }
        }
        .navigationTitle(project.name)
        .task(id: project.floorplanJSONURL) {
            await loadFloorplan()
        }
    }

    @ViewBuilder
    private var floorplanTab: some View {
        Group {
            if let floorplan {
                FloorplanView(model: floorplan)
            } else if let floorplanError {
                ContentUnavailableView(
                    "Unable to load floorplan",
                    systemImage: "exclamationmark.triangle",
                    description: Text(floorplanError)
                )
            } else {
                if project.floorplanJSONURL == nil {
                    ContentUnavailableView(
                        "No floorplan available",
                        systemImage: "document",
                        description: Text("This project does not have a saved 2D plan.")
                    )
                } else {
                    ProgressView("Loading floorplan…")
                }
            }
        }
        .tabItem {
            Label("2D Plan", systemImage: "square.grid.2x2")
        }
    }

    private func loadFloorplan() async {
        guard let floorplanURL = project.floorplanJSONURL else {
            return
        }

        do {
            let data = try Data(contentsOf: floorplanURL)
            let decoded = try JSONDecoder().decode(FloorplanModel.self, from: data)
            await MainActor.run {
                floorplan = decoded
                floorplanError = nil
            }
        } catch {
            await MainActor.run {
                floorplan = nil
                floorplanError = error.localizedDescription
            }
        }
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
