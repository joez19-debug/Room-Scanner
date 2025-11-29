import SwiftUI
import CoreGraphics

struct FloorplanView: View {
    let model: FloorplanModel

    @State private var zoom: CGFloat = 1.0
    @State private var baseZoom: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var hasInitializedView = false

    private var planBounds: CGRect {
        var minX = CGFloat.greatestFiniteMagnitude
        var maxX = -CGFloat.greatestFiniteMagnitude
        var minY = CGFloat.greatestFiniteMagnitude
        var maxY = -CGFloat.greatestFiniteMagnitude

        // walls
        for wall in model.walls {
            minX = min(minX, wall.start.x, wall.end.x)
            maxX = max(maxX, wall.start.x, wall.end.x)
            minY = min(minY, wall.start.y, wall.end.y)
            maxY = max(maxY, wall.start.y, wall.end.y)
        }

        // furniture centers (optionally expand by half size)
        for item in model.furniture {
            let halfW = item.size.width / 2.0
            let halfH = item.size.height / 2.0
            minX = min(minX, item.position.x - halfW)
            maxX = max(maxX, item.position.x + halfW)
            minY = min(minY, item.position.y - halfH)
            maxY = max(maxY, item.position.y + halfH)
        }

        if minX == .greatestFiniteMagnitude {
            return .zero
        }
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                let bounds = planBounds
                let midX = bounds.midX
                let midY = bounds.midY
                let transform = CGAffineTransform.identity
                    .translatedBy(x: size.width / 2, y: size.height / 2)
                    .translatedBy(x: offset.width, y: offset.height)
                    .scaledBy(x: zoom, y: zoom)
                    .translatedBy(x: -midX, y: -midY)

                drawWalls(in: &context, transform: transform)
                drawOpenings(in: &context, transform: transform)
                drawFurniture(in: &context, transform: transform)
            }
            .gesture(dragGesture().simultaneously(with: magnificationGesture()))
            .onAppear {
                if !hasInitializedView {
                    resetView(for: geo.size)
                    hasInitializedView = true
                }
            }
            .onChange(of: planBounds) {
                if !hasInitializedView {
                    resetView(for: geo.size)
                    hasInitializedView = true
                }
            }
        }
    }

    // MARK: - Drawing helpers

    private func drawWalls(in context: inout GraphicsContext, transform: CGAffineTransform) {
        for wall in model.walls {
            var path = Path()
            path.move(to: wall.start.applying(transform))
            path.addLine(to: wall.end.applying(transform))
            context.stroke(path, with: .color(.primary), lineWidth: 2)

            let midpoint = CGPoint(x: (wall.start.x + wall.end.x) / 2, y: (wall.start.y + wall.end.y) / 2)
            let labelPosition = midpoint.applying(transform)
            let length = distance(from: wall.start, to: wall.end)
            let label = lengthFormatter.string(from: Measurement(value: length, unit: UnitLength.meters))
            let text = Text(label).font(.caption2)
            context.draw(text, at: labelPosition, anchor: .center)
        }
    }

    private func drawOpenings(in context: inout GraphicsContext, transform: CGAffineTransform) {
        for opening in model.openings {
            let center = opening.center.applying(transform)
            let rect = CGRect(x: center.x - opening.width / 2 * zoom,
                              y: center.y - 2,
                              width: opening.width * zoom,
                              height: 4)
            context.fill(Path(rect), with: .color(.secondary))
        }
    }

    private func drawFurniture(in context: inout GraphicsContext, transform: CGAffineTransform) {
        for item in model.furniture {
            let position = item.position.applying(transform)
            let size = CGSize(width: item.size.width * zoom, height: item.size.height * zoom)
            var rect = CGRect(origin: .zero, size: size)
            rect.origin = CGPoint(x: position.x - size.width / 2, y: position.y - size.height / 2)
            var path = Path(rect)
            path = path.applying(CGAffineTransform(translationX: position.x - rect.midX, y: position.y - rect.midY))
            context.stroke(path, with: .color(.blue), lineWidth: 1)
        }
    }

    // MARK: - Gestures

    private func dragGesture() -> some Gesture {
        DragGesture()
            .onChanged { value in
                offset = CGSize(width: lastOffset.width + value.translation.width,
                                 height: lastOffset.height + value.translation.height)
            }
            .onEnded { _ in
                lastOffset = offset
            }
    }

    private func magnificationGesture() -> some Gesture {
        MagnificationGesture()
            .onChanged { scale in
                zoom = baseZoom * scale
            }
            .onEnded { _ in
                baseZoom = zoom
            }
    }

    // MARK: - Utilities

    private let lengthFormatter: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .providedUnit
        formatter.unitStyle = .medium
        formatter.numberFormatter.maximumFractionDigits = 2
        return formatter
    }()

    private func distance(from a: CGPoint, to b: CGPoint) -> Double {
        let dx = Double(b.x - a.x)
        let dy = Double(b.y - a.y)
        return sqrt(dx * dx + dy * dy)
    }

    private func resetView(for size: CGSize) {
        let bounds = planBounds
        guard bounds.width > 0, bounds.height > 0 else { return }

        let availableWidth = size.width
        let availableHeight = size.height

        let scaleX = availableWidth / bounds.width
        let scaleY = availableHeight / bounds.height
        let scale = 0.8 * min(scaleX, scaleY)

        zoom = scale
        baseZoom = scale

        let planCenter = CGPoint(x: bounds.midX, y: bounds.midY)
        let viewCenter = CGPoint(x: availableWidth / 2.0, y: availableHeight / 2.0)

        offset = CGSize(
            width: viewCenter.x - zoom * planCenter.x,
            height: viewCenter.y - zoom * planCenter.y
        )
        lastOffset = offset
    }
}

#Preview {
    let wall = WallSegment2D(id: UUID(), start: CGPoint(x: -1, y: 0), end: CGPoint(x: 1, y: 0), thickness: 0.1, isStructural: true)
    let model = FloorplanModel(bounds: CGRect(x: -2, y: -2, width: 4, height: 4), walls: [wall], openings: [], furniture: [])
    return FloorplanView(model: model)
}
