import SwiftUI
import RoomPlan

struct RoomCaptureViewRepresentable: UIViewControllerRepresentable {
    @ObservedObject var viewModel: RoomScanViewModel

    func makeUIViewController(context: Context) -> RoomCaptureViewController {
        let controller = RoomCaptureViewController()
        controller.viewModel = viewModel
        viewModel.captureController = controller
        return controller
    }

    func updateUIViewController(_ uiViewController: RoomCaptureViewController, context: Context) {
        // No-op for now; state is driven by the view model.
    }
}
