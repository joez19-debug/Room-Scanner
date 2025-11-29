//
//  Room_ScannerApp.swift
//  Room-Scanner
//
//  Created by Joe Ziegler on 11/28/25.
//

import SwiftUI

@main
struct Room_ScannerApp: App {
    @StateObject private var projectStore = RoomProjectStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(projectStore)
                .task {
                    projectStore.loadProjects()
                }
        }
    }
}
