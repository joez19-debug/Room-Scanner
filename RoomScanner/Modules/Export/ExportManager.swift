import Foundation

enum ExportFormat {
    case usdz
    case floorplanJSON
    case floorplanSVG
}

final class ExportManager {
    func urlForExport(project: RoomProject, format: ExportFormat) -> URL {
        switch format {
        case .usdz:
            return project.usdzFileURL
        case .floorplanJSON:
            return project.floorplanJSONURL ?? project.usdzFileURL.deletingLastPathComponent().appendingPathComponent("floorplan.json")
        case .floorplanSVG:
            return project.usdzFileURL.deletingPathExtension().appendingPathExtension("svg")
        }
    }

    func export(project: RoomProject, floorplan: FloorplanModel, format: ExportFormat) throws -> URL {
        switch format {
        case .usdz:
            return project.usdzFileURL
        case .floorplanJSON:
            let url = urlForExport(project: project, format: .floorplanJSON)
            let data = try JSONEncoder().encode(floorplan)
            try data.write(to: url, options: .atomic)
            return url
        case .floorplanSVG:
            let url = urlForExport(project: project, format: .floorplanSVG)
            try generateSVG(for: floorplan).write(to: url, atomically: true, encoding: .utf8)
            return url
        }
    }

    private func generateSVG(for model: FloorplanModel) -> String {
        let header = "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 \(model.bounds.width) \(model.bounds.height)\">"
        let walls = model.walls.map { wall in
            "<line x1=\"\(wall.start.x)\" y1=\"\(wall.start.y)\" x2=\"\(wall.end.x)\" y2=\"\(wall.end.y)\" stroke=\"black\" stroke-width=\"\(wall.thickness)\" />"
        }.joined()
        let footer = "</svg>"
        return header + walls + footer
    }
}
