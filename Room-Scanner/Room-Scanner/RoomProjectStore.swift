import Foundation
import RoomPlan
import SwiftUI

final class RoomProjectStore: ObservableObject {
    @Published var projects: [RoomProject] = []

    private let fileManager: FileManager
    private let floorplanBuilder: FloorplanBuilder
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(
        fileManager: FileManager = .default,
        floorplanBuilder: FloorplanBuilder = FloorplanBuilder(),
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.fileManager = fileManager
        self.floorplanBuilder = floorplanBuilder
        self.encoder = encoder
        self.decoder = decoder
    }

    // MARK: - Loading

    func loadProjects() {
        do {
            let projectsDirectory = try fileManager.projectsDirectory()
            let projectFolders = try fileManager.contentsOfDirectory(
                at: projectsDirectory,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            )

            var loadedProjects: [RoomProject] = []

            for folder in projectFolders {
                do {
                    var isDirectory: ObjCBool = false
                    guard fileManager.fileExists(atPath: folder.path, isDirectory: &isDirectory), isDirectory.boolValue else {
                        continue
                    }

                    let metaURL = folder.appendingPathComponent("meta.json")
                    let metaData = try Data(contentsOf: metaURL)
                    var project = try decoder.decode(RoomProject.self, from: metaData)

                    let usdzURL = folder.appendingPathComponent("room.usdz")
                    project.usdzFileURL = usdzURL

                    let floorplanURL = folder.appendingPathComponent("floorplan.json")
                    project.floorplanJSONURL = fileManager.fileExists(atPath: floorplanURL.path) ? floorplanURL : nil

                    loadedProjects.append(project)
                } catch {
                    print("Skipping corrupt project at \(folder.lastPathComponent): \(error)")
                    continue
                }
            }

            DispatchQueue.main.async {
                self.projects = loadedProjects
            }
        } catch {
            print("Failed to load projects: \(error)")
        }
    }

    // MARK: - Creation

    func createProject(from capturedRoom: CapturedRoom, name: String?) async throws -> RoomProject {
        let projectsDirectory = try fileManager.projectsDirectory()
        let projectId = UUID()
        let projectFolder = projectsDirectory.appendingPathComponent(projectId.uuidString, isDirectory: true)
        try fileManager.createDirectory(at: projectFolder, withIntermediateDirectories: true, attributes: nil)

        let createdAt = Date()
        let usdzURL = projectFolder.appendingPathComponent("room.usdz")
        let floorplanURL = projectFolder.appendingPathComponent("floorplan.json")

        let floorplan = floorplanBuilder.build(from: capturedRoom)
        let floorplanData = try encoder.encode(floorplan)

        do {
            try await capturedRoom.export(to: usdzURL)
            try floorplanData.write(to: floorplanURL)
        } catch {
            throw NSError(
                domain: "RoomProjectStore",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Failed to persist project assets: \(error.localizedDescription)"]
            )
        }

        let persistedProject = RoomProject(
            id: projectId,
            name: name ?? Self.defaultProjectName(date: createdAt),
            createdAt: createdAt,
            updatedAt: createdAt,
            usdzFileURL: URL(filePath: "room.usdz"),
            floorplanJSONURL: URL(filePath: "floorplan.json"),
            notes: nil
        )

        let metaURL = projectFolder.appendingPathComponent("meta.json")
        do {
            try encoder.encode(persistedProject).write(to: metaURL)
        } catch {
            throw NSError(
                domain: "RoomProjectStore",
                code: 3,
                userInfo: [NSLocalizedDescriptionKey: "Failed to save project metadata: \(error.localizedDescription)"]
            )
        }

        let project = RoomProject(
            id: projectId,
            name: persistedProject.name,
            createdAt: createdAt,
            updatedAt: createdAt,
            usdzFileURL: usdzURL,
            floorplanJSONURL: floorplanURL,
            notes: nil
        )

        await MainActor.run {
            self.projects.append(project)
        }

        return project
    }

    // MARK: - Deletion

    func deleteProject(_ project: RoomProject) throws {
        let projectFolder = try projectFolderURL(for: project)
        do {
            if fileManager.fileExists(atPath: projectFolder.path) {
                try fileManager.removeItem(at: projectFolder)
            }

            if let index = projects.firstIndex(of: project) {
                projects.remove(at: index)
            }
        } catch {
            throw NSError(
                domain: "RoomProjectStore",
                code: 4,
                userInfo: [NSLocalizedDescriptionKey: "Failed to delete project: \(error.localizedDescription)"]
            )
        }
    }

    // MARK: - Helpers

    private func projectFolderURL(for project: RoomProject) throws -> URL {
        let projectsDirectory = try fileManager.projectsDirectory()
        return projectsDirectory.appendingPathComponent(project.id.uuidString, isDirectory: true)
    }

    private static func defaultProjectName(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return "Room \(formatter.string(from: date))"
    }
}

// MARK: - FileManager helpers

extension FileManager {
    func documentsDirectory() throws -> URL {
        guard let url = urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw NSError(
                domain: "RoomProjectStore",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "Unable to locate the Documents directory"]
            )
        }
        return url
    }

    func projectsDirectory() throws -> URL {
        let documents = try documentsDirectory()
        let projects = documents.appendingPathComponent("Projects", isDirectory: true)

        var isDirectory: ObjCBool = false
        if fileExists(atPath: projects.path, isDirectory: &isDirectory) {
            guard isDirectory.boolValue else {
                throw NSError(
                    domain: "RoomProjectStore",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "Projects path exists but is not a directory"]
                )
            }
        } else {
            try createDirectory(at: projects, withIntermediateDirectories: true, attributes: nil)
        }

        return projects
    }
}
