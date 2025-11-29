import RealityKit
import SwiftUI

final class Room3DViewModel: ObservableObject {
    @Published var modelEntity: ModelEntity?

    func loadModel(from url: URL) async {
        do {
            let entity = try await ModelEntity.load(contentsOf: url)
            await MainActor.run { self.modelEntity = entity }
        } catch {
            print("Failed to load USDZ: \(error)")
        }
    }
}

struct Room3DView: UIViewRepresentable {
    @ObservedObject var viewModel: Room3DViewModel

    func makeUIView(context: Context) -> ARView {
        let view = ARView(frame: .zero)
        view.environment.background = .color(.systemBackground)
        return view
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        uiView.scene.anchors.removeAll()
        if let entity = viewModel.modelEntity {
            let anchor = AnchorEntity(world: .zero)
            anchor.addChild(entity)
            uiView.scene.addAnchor(anchor)
        }
    }
}
