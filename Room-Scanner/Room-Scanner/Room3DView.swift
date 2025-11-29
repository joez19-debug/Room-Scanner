import RealityKit
import SwiftUI

struct Room3DView: UIViewRepresentable {
    @ObservedObject var viewModel: Room3DViewModel

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero, cameraMode: .nonAR, automaticallyConfigureSession: false)
        arView.environment.sceneUnderstanding.options = []
        arView.debugOptions = []

        let rootAnchor = AnchorEntity(world: .zero)
        arView.scene.addAnchor(rootAnchor)
        context.coordinator.rootAnchor = rootAnchor

        let cameraAnchor = AnchorEntity(world: .zero)
        let camera = PerspectiveCamera()
        var cameraTransform = Transform(pitch: -.pi / 12, yaw: .pi, roll: 0)
        cameraTransform.translation = [0, 1.5, 3]
        camera.transform = cameraTransform
        cameraAnchor.addChild(camera)
        arView.scene.addAnchor(cameraAnchor)

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        context.coordinator.updateModel(viewModel.modelEntity, in: uiView)
    }

    final class Coordinator {
        var rootAnchor: AnchorEntity?
        private var currentModel: ModelEntity?

        func updateModel(_ model: ModelEntity?, in arView: ARView) {
            guard let rootAnchor else { return }

            if currentModel != model {
                currentModel?.removeFromParent()
                currentModel = model
            }

            guard let modelEntity = model else { return }

            if modelEntity.parent == nil {
                rootAnchor.addChild(modelEntity)
                modelEntity.generateCollisionShapes(recursive: true)
                arView.installGestures([.rotation, .translation, .scale], for: modelEntity)
            }
        }
    }
}
