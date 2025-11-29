import SwiftUI
import RoomPlan

struct RoomScanScreen: View {
    @StateObject private var viewModel = RoomScanViewModel()

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

                Button(action: viewModel.finishScan) {
                    Label("Finish", systemImage: "stop.fill")
                }
                .disabled(!viewModel.isScanning)
            }
            .padding()

            Text(viewModel.capturedRoom == nil ? "No capture yet" : "Captured room available")
                .padding(.bottom)
        }
    }
}

#Preview {
    RoomScanScreen()
}
