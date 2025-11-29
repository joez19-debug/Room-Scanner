import SwiftUI

@main
struct RoomScannerApp: App {
    @StateObject private var store = FileRoomProjectStore()

    var body: some Scene {
        WindowGroup {
            ProjectsListView(store: store)
        }
    }
}
