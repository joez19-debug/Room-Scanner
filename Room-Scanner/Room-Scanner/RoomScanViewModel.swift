import Foundation
import RoomPlan
import Combine

@MainActor
final class RoomScanViewModel: ObservableObject {
    @Published var isScanning: Bool = false
    @Published var capturedRoom: CapturedRoom?
    @Published var scanErrorMessage: String?

    weak var captureController: RoomCaptureViewController?

    func startScan() {
        guard RoomCaptureSession.isSupported else {
            scanErrorMessage = "Room capture is not supported on this device."
            isScanning = false
            print("RoomScanViewModel.startScan aborted: capture not supported")
            return
        }

        guard let captureController else {
            scanErrorMessage = "Capture controller is unavailable."
            isScanning = false
            print("RoomScanViewModel.startScan aborted: captureController nil")
            return
        }

        scanErrorMessage = nil
        captureController.startSession()
        isScanning = true
    }

    func stopScan() {
        guard let captureController else {
            print("RoomScanViewModel.stopScan skipped: captureController nil")
            return
        }

        captureController.stopSession()
        isScanning = false
    }

    func finishScan() {
        guard let captureController else {
            print("RoomScanViewModel.finishScan skipped: captureController nil")
            return
        }

        captureController.finishSession()
        isScanning = false
    }
}
