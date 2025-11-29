import UIKit
import RoomPlan

final class RoomCaptureViewController: UIViewController, RoomCaptureSessionDelegate {
    private let roomCaptureView = RoomCaptureView(frame: .zero)
    weak var viewModel: RoomScanViewModel?

    override func loadView() {
        view = roomCaptureView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        roomCaptureView.captureSession.delegate = self
    }

    func startSession() {
        let configuration = RoomCaptureSession.Configuration()
        roomCaptureView.captureSession.run(configuration: configuration)
        viewModel?.isScanning = true
    }

    func stopSession() {
        roomCaptureView.captureSession.stop()
        viewModel?.isScanning = false
    }

    func finishSession() {
        roomCaptureView.captureSession.stop()
    }

    func captureSession(_ session: RoomCaptureSession, didUpdate sessionData: CapturedRoom) {
        // Keep track of the latest captured room in case the delegate wants live updates.
        viewModel?.capturedRoom = sessionData
    }

    func captureSession(_ session: RoomCaptureSession, didEndWith data: CapturedRoom, error: (any Error)?) {
        viewModel?.capturedRoom = data
        viewModel?.isScanning = false
    }
}
