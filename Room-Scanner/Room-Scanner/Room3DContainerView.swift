import SwiftUI

struct Room3DContainerView: View {
    private let usdzURL: URL
    @StateObject private var viewModel = Room3DViewModel()

    init(project: RoomProject) {
        self.usdzURL = project.usdzFileURL
    }

    init(usdzURL: URL) {
        self.usdzURL = usdzURL
    }

    var body: some View {
        ZStack {
            Room3DView(viewModel: viewModel)
                .task(id: usdzURL) {
                    await viewModel.loadModel(from: usdzURL)
                }

            if viewModel.modelEntity == nil {
                ProgressView("Loading 3D model…")
            }
        }
        .navigationTitle("3D View")
    }
}

#Preview {
    Room3DContainerView(usdzURL: URL(filePath: "/tmp/dummy.usdz"))
}
