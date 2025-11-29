import Foundation
import Combine
import RoomPlan

final class RoomScanViewModel: ObservableObject {
    @Published var isScanning: Bool = false
    @Published var capturedRoom: CapturedRoom?

    weak var captureController: RoomCaptureViewController?

    func startScan() {
        captureController?.startSession()
        isScanning = true
    }

    func stopScan() {
        captureController?.stopSession()
        isScanning = false
    }

    func finishScan() {
        captureController?.finishSession()
        isScanning = false
    }
}
