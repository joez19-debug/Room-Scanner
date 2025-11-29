import SwiftUI
import UIKit

struct ProjectDetailView: View {
    let project: RoomProject
    @StateObject private var viewModel = Room3DViewModel()
    @State private var floorplan: FloorplanModel = .init(bounds: .zero, walls: [], openings: [], furniture: [])
    @State private var selection: Int = 0
    @State private var exportURL: URL?
    @State private var isSharing = false
    private let exportManager = ExportManager()

    var body: some View {
        VStack {
            Picker("View", selection: $selection) {
                Text("3D View").tag(0)
                Text("2D Plan").tag(1)
            }
            .pickerStyle(.segmented)
            .padding()

            if selection == 0 {
                Room3DView(viewModel: viewModel)
            } else {
                FloorplanView(model: floorplan)
            }
        }
        .navigationTitle(project.name)
        .task {
            await viewModel.loadModel(from: project.usdzFileURL)
            loadFloorplan()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("Export USDZ") { share(format: .usdz) }
                    Button("Export Floorplan JSON") { share(format: .floorplanJSON) }
                    Button("Export Floorplan SVG") { share(format: .floorplanSVG) }
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
            }
        }
        .sheet(isPresented: $isSharing, onDismiss: { exportURL = nil }) {
            if let exportURL {
                ShareSheet(activityItems: [exportURL])
            }
        }
    }

    private func loadFloorplan() {
        guard let url = project.floorplanJSONURL,
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(FloorplanModel.self, from: data) else { return }
        floorplan = decoded
    }

    private func share(format: ExportFormat) {
        guard let export = try? exportManager.export(project: project, floorplan: floorplan, format: format) else { return }
        exportURL = export
        isSharing = true
    }
}

private struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
