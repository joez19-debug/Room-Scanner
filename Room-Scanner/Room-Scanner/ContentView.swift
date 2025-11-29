//
//  ContentView.swift
//  Room-Scanner
//
//  Created by Joe Ziegler on 11/28/25.
//

import SwiftUI

private enum Route: Hashable {
    case scan
    case project(RoomProject)
}

struct ContentView: View {
    @EnvironmentObject private var projectStore: RoomProjectStore
    @State private var path: [Route] = []

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Section("Projects") {
                    if projectStore.projects.isEmpty {
                        Text("No projects yet")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(projectStore.projects) { project in
                            NavigationLink(project.name, value: Route.project(project))
                        }
                    }
                }
            }
            .navigationTitle("Room Scanner")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: startNewScan) {
                        Label("New Scan", systemImage: "plus")
                    }
                }
            }
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .scan:
                    RoomScanScreen(onFinished: handleScanFinished)
                case .project(let project):
                    ProjectDetailView(project: project)
                }
            }
        }
    }

    private func startNewScan() {
        path.append(.scan)
    }

    private func handleScanFinished(_ project: RoomProject) {
        path = []
    }
}

#Preview {
    ContentView()
        .environmentObject(RoomProjectStore())
}
