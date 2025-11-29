import SwiftUI
import RoomPlan

struct RoomScanScreen: View {
    @StateObject private var viewModel = RoomScanViewModel()
    @EnvironmentObject private var projectStore: RoomProjectStore
    @State private var projectName: String = ""
    @State private var isSaving: Bool = false
    @State private var saveError: String?

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

            if let scanError = viewModel.scanErrorMessage {
                Text(scanError)
                    .foregroundColor(.red)
                    .padding(.horizontal)
                    .padding(.bottom)
            }

            if viewModel.capturedRoom != nil {
                TextField("Project Name", text: $projectName)
                    .textFieldStyle(.roundedBorder)
                    .padding([.horizontal, .bottom])

                Button(action: saveProject) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Label("Save Project", systemImage: "square.and.arrow.down")
                    }
                }
                .disabled(isSaving)
                .padding(.bottom)
            }
        }
        .alert("Unable to Save Project", isPresented: Binding(
            get: { saveError != nil },
            set: { newValue in
                if !newValue { saveError = nil }
            }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            if let saveError {
                Text(saveError)
            }
        }
        .alert("Scan Error", isPresented: Binding(
            get: { viewModel.scanErrorMessage != nil },
            set: { newValue in
                if !newValue { viewModel.scanErrorMessage = nil }
            }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            if let scanErrorMessage = viewModel.scanErrorMessage {
                Text(scanErrorMessage)
            }
        }
    }

    private func finishScan() {
        viewModel.finishScan()
    }

    private func saveProject() {
        guard let capturedRoom = viewModel.capturedRoom else {
            print("No capturedRoom available; cannot save project")
            return
        }
        isSaving = true

        Task {
            do {
                let project = try await projectStore.createProject(
                    from: capturedRoom,
                    name: projectName.isEmpty ? nil : projectName
                )
                projectName = ""
                onFinished?(project)
            } catch {
                saveError = error.localizedDescription
            }

            isSaving = false
        }
    }
}

#Preview {
    RoomScanScreen()
        .environmentObject(RoomProjectStore())
}
