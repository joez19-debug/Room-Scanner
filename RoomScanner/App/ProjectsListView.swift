import SwiftUI

struct ProjectsListView: View {
    @ObservedObject var store: FileRoomProjectStore
    @State private var showingScanner = false

    var body: some View {
        NavigationStack {
            List(store.projects) { project in
                NavigationLink(project.name) {
                    ProjectDetailView(project: project)
                }
            }
            .navigationTitle("Projects")
            .toolbar {
                Button(action: { showingScanner = true }) {
                    Label("New Scan", systemImage: "plus")
                }
            }
            .sheet(isPresented: $showingScanner) {
                RoomScanScreen(store: store)
            }
            .task {
                try? store.loadAllProjects()
            }
        }
    }
}

struct ProjectsListView_Previews: PreviewProvider {
    static var previews: some View {
        ProjectsListView(store: FileRoomProjectStore())
    }
}
