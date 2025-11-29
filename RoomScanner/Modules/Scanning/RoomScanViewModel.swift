import Foundation
import RoomPlan
import SwiftUI

@MainActor
final class RoomScanViewModel: ObservableObject {
    @Published var isScanning: Bool = false
    @Published var capturedRoom: CapturedRoom?
    @Published var canFinish: Bool = false
    @Published var statusMessage: String?

    func startScan() {
        isScanning = true
        statusMessage = "Move slowly to capture the room"
    }

    func stopScan() {
        isScanning = false
        statusMessage = nil
    }

    func finishScan() {
        guard capturedRoom != nil else { return }
        stopScan()
    }

    func updateCapture(_ room: CapturedRoom) {
        capturedRoom = room
        canFinish = true
        statusMessage = "Scan ready to save"
    }
}
