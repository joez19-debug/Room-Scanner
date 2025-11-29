import Foundation

protocol RoomProjectStore: AnyObject {
    func loadAllProjects() throws -> [RoomProject]
    func save(_ project: RoomProject, floorplan: FloorplanModel) throws
    func delete(_ project: RoomProject) throws
}

final class FileRoomProjectStore: ObservableObject, RoomProjectStore {
    @Published private(set) var projects: [RoomProject] = []

    private let fileManager: FileManager
    private let projectsDirectory: URL

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        self.projectsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Projects", isDirectory: true)
        try? fileManager.createDirectory(at: projectsDirectory, withIntermediateDirectories: true)

        // Attempt to eagerly load any saved projects so the UI has data on launch.
        _ = try? loadAllProjects()
    }

    func loadAllProjects() throws -> [RoomProject] {
        let url = metadataURL()
        guard fileManager.fileExists(atPath: url.path) else {
            projects = []
            try persistProjects(projects)
            return projects
        }

        let data = try Data(contentsOf: url)
        let projects = try JSONDecoder().decode([RoomProject].self, from: data)
        self.projects = projects
        return projects
    }

    func save(_ project: RoomProject, floorplan: FloorplanModel) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let updatedProjects = projectsIncluding(project)
        try persistProjects(updatedProjects)

        let floorplanData = try encoder.encode(floorplan)
        if let floorplanURL = project.floorplanJSONURL {
            try fileManager.createDirectory(at: floorplanURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try floorplanData.write(to: floorplanURL, options: .atomic)
        }
    }

    func delete(_ project: RoomProject) throws {
        projects.removeAll { $0.id == project.id }
        let data = try JSONEncoder().encode(projects)
        try data.write(to: metadataURL(), options: .atomic)

        try? fileManager.removeItem(at: project.usdzFileURL)
        if let floorplanURL = project.floorplanJSONURL {
            try? fileManager.removeItem(at: floorplanURL)
        }
    }

    private func metadataURL() -> URL {
        projectsDirectory.appendingPathComponent("meta.json")
    }

    private func persistProjects(_ projects: [RoomProject]) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(projects)
        try data.write(to: metadataURL(), options: .atomic)
    }

    private func projectsIncluding(_ project: RoomProject) -> [RoomProject] {
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            projects[index] = project
            return projects
        }

        var updated = projects
        updated.append(project)
        projects = updated
        return updated
    }
}
