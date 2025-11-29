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
        guard RoomCaptureSession.isSupported else {
            print("RoomCaptureSession not supported; cannot start session")
            DispatchQueue.main.async { [weak self] in
                self?.viewModel?.scanErrorMessage = "Room capture is not supported on this device."
                self?.viewModel?.isScanning = false
            }
            return
        }

        let configuration = RoomCaptureSession.Configuration()
        print("Starting RoomCaptureSession with configuration: \(configuration)")
        roomCaptureView.captureSession.run(configuration: configuration)
        DispatchQueue.main.async { [weak self] in
            self?.viewModel?.isScanning = true
        }
    }

    func stopSession() {
        print("Stopping RoomCaptureSession")
        roomCaptureView.captureSession.stop()
        DispatchQueue.main.async { [weak self] in
            self?.viewModel?.isScanning = false
        }
    }

    func finishSession() {
        print("Finishing RoomCaptureSession")
        roomCaptureView.captureSession.stop()
    }

    func captureSession(_ session: RoomCaptureSession, didUpdate sessionData: CapturedRoom) {
        // Keep track of the latest captured room in case the delegate wants live updates.
        print("RoomCaptureSession didUpdate: surfaces=\(sessionData.walls.count) walls, objects=\(sessionData.objects.count)")
        DispatchQueue.main.async { [weak self] in
            self?.viewModel?.capturedRoom = sessionData
        }
    }

    func captureSession(_ session: RoomCaptureSession, didEndWith data: CapturedRoom, error: (any Error)?) {
        if let error {
            print("RoomCaptureSession didEnd with error: \(error)")
        } else {
            print("RoomCaptureSession didEnd with capturedRoom: \(data)")
        }
        DispatchQueue.main.async { [weak self] in
            if let error {
                self?.viewModel?.capturedRoom = nil
                self?.viewModel?.scanErrorMessage = error.localizedDescription
            } else {
                self?.viewModel?.capturedRoom = data
                self?.viewModel?.scanErrorMessage = nil
            }
            self?.viewModel?.isScanning = false
        }
    }
}
