import SwiftUI
import RoomPlan

struct RoomScanScreen: View {
    @StateObject private var viewModel = RoomScanViewModel()
    var onFinished: ((RoomProject) -> Void)? = nil

    var body: some View {
        VStack {
            RoomCaptureViewRepresentable(viewModel: viewModel)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(UIColor.systemBackground))

            HStack {
                Button(action: viewModel.startScan) {
                    Label("Start Scan", systemImage: "play.fill")
                }
                .disabled(viewModel.isScanning)

                Button(action: finishScan) {
                    Label("Finish", systemImage: "stop.fill")
                }
                .disabled(!viewModel.isScanning)
            }
            .padding()

            Text(viewModel.capturedRoom == nil ? "No capture yet" : "Captured room available")
                .padding(.bottom)
        }
    }

    private func finishScan() {
        viewModel.finishScan()

        let dummyProject = RoomProject(
            id: UUID(),
            name: "New Scan",
            createdAt: Date(),
            updatedAt: Date(),
            usdzFileURL: URL(filePath: "/tmp/new-scan.usdz"),
            floorplanJSONURL: nil,
            notes: nil
        )

        onFinished?(dummyProject)
    }
}

#Preview {
    RoomScanScreen()
}
