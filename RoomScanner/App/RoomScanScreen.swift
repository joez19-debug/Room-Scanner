import SwiftUI

struct RoomScanScreen: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: FileRoomProjectStore
    @StateObject private var viewModel = RoomScanViewModel()
    private let builder = FloorplanBuilder()
    @State private var errorMessage: String?

    var body: some View {
        VStack {
            RoomCaptureViewRepresentable(viewModel: viewModel)
                .edgesIgnoringSafeArea(.all)
                .overlay(alignment: .bottom) {
                    if let status = viewModel.statusMessage {
                        Text(status)
                            .padding(8)
                            .background(.ultraThinMaterial)
                            .cornerRadius(8)
                            .padding()
                    }
                }

            HStack {
                Button("Cancel") {
                    viewModel.finishScan()
                    dismiss()
                }
                Spacer()
                Button("Done") { saveCapture() }
                    .disabled(!viewModel.canFinish)
            }
            .padding()
        }
        .onAppear { viewModel.startScan() }
        .onDisappear { viewModel.stopScan() }
        .alert("Save Failed", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "Unknown error")
        }
    }

    private func saveCapture() {
        guard let capturedRoom = viewModel.capturedRoom else { return }
        let projectId = UUID()
        let projectDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Projects/\(projectId)", isDirectory: true)

        do {
            try FileManager.default.createDirectory(at: projectDirectory, withIntermediateDirectories: true)

            let usdzURL = projectDirectory.appendingPathComponent("room.usdz")
            try capturedRoom.export(to: usdzURL)

            let floorplan = builder.build(from: capturedRoom)
            let floorplanURL = projectDirectory.appendingPathComponent("floorplan.json")
            let encodedFloorplan = try JSONEncoder().encode(floorplan)
            try encodedFloorplan.write(to: floorplanURL)

            let project = RoomProject(
                id: projectId,
                name: "Scan \(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short))",
                createdAt: Date(),
                updatedAt: Date(),
                usdzFileURL: usdzURL,
                floorplanJSONURL: floorplanURL,
                notes: nil
            )

            try store.save(project, floorplan: floorplan)
            viewModel.finishScan()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
