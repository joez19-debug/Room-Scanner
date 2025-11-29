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
        DispatchQueue.main.async { [weak self] in
            self?.viewModel?.isScanning = true
        }
    }

    func stopSession() {
        roomCaptureView.captureSession.stop()
        DispatchQueue.main.async { [weak self] in
            self?.viewModel?.isScanning = false
        }
    }

    func finishSession() {
        roomCaptureView.captureSession.stop()
    }

    func captureSession(_ session: RoomCaptureSession, didUpdate sessionData: CapturedRoom) {
        // Keep track of the latest captured room in case the delegate wants live updates.
        DispatchQueue.main.async { [weak self] in
            self?.viewModel?.capturedRoom = sessionData
        }
    }

    func captureSession(_ session: RoomCaptureSession, didEndWith data: CapturedRoom, error: (any Error)?) {
        DispatchQueue.main.async { [weak self] in
            self?.viewModel?.capturedRoom = data
            self?.viewModel?.isScanning = false
        }
    }
}
