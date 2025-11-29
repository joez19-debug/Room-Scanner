import RoomPlan
import SwiftUI
import UIKit

final class RoomCaptureViewController: UIViewController {
    private let captureView = RoomCaptureView(frame: .zero)
    private let session = RoomCaptureSession()
    private let sessionConfig = RoomCaptureSession.Configuration()
    weak var delegate: RoomCaptureSessionDelegate? {
        didSet { session.delegate = delegate }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCaptureView()
    }

    private func setupCaptureView() {
        captureView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(captureView)
        NSLayoutConstraint.activate([
            captureView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            captureView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            captureView.topAnchor.constraint(equalTo: view.topAnchor),
            captureView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        captureView.captureSession = session
    }

    func startCapture() {
        session.run(configuration: sessionConfig)
    }

    func stopCapture() {
        session.stop()
    }
}

struct RoomCaptureViewRepresentable: UIViewControllerRepresentable {
    @ObservedObject var viewModel: RoomScanViewModel

    func makeUIViewController(context: Context) -> RoomCaptureViewController {
        let controller = RoomCaptureViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: RoomCaptureViewController, context: Context) {
        viewModel.isScanning ? uiViewController.startCapture() : uiViewController.stopCapture()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    final class Coordinator: NSObject, RoomCaptureSessionDelegate {
        private let viewModel: RoomScanViewModel

        init(viewModel: RoomScanViewModel) {
            self.viewModel = viewModel
        }

        func captureSession(_ session: RoomCaptureSession, didUpdate: CapturedRoom) {
            viewModel.updateCapture(didUpdate)
        }

        func captureSession(_ session: RoomCaptureSession, didEndWith data: CapturedRoomData, error: (any Error)?) {
            if let finalRoom = data.room {
                viewModel.updateCapture(finalRoom)
            }
            if let error {
                print("Room capture ended with error: \(error)")
            }
        }
    }
}
