import Foundation
import RealityKit
import SwiftUI

@MainActor
final class Room3DViewModel: ObservableObject {
    @Published var modelEntity: ModelEntity?

    func loadModel(from url: URL) async {
        do {
            let loadedModel = try await ModelEntity.load(contentsOf: url)
            modelEntity = loadedModel
        } catch {
            print("Failed to load USDZ model: \(error)")
            modelEntity = nil
        }
    }
}
