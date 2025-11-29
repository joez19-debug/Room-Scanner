import SwiftUI

struct FloorplanView: View {
    let model: FloorplanModel

    @State private var zoom: CGFloat = 1.0
    @State private var offset: CGSize = .zero

    var body: some View {
        GeometryReader { _ in
            Canvas { context, _ in
                let transform = CGAffineTransform
                    .identity
                    .translatedBy(x: offset.width, y: offset.height)
                    .scaledBy(x: zoom, y: zoom)

                for wall in model.walls {
                    var path = Path()
                    path.move(to: wall.start.applying(transform))
                    path.addLine(to: wall.end.applying(transform))
                    context.stroke(path, with: .color(.label), lineWidth: 2)
                }

                for opening in model.openings {
                    let rect = CGRect(x: opening.center.x - opening.width / 2,
                                      y: opening.center.y - 0.05,
                                      width: opening.width,
                                      height: 0.1)
                        .applying(transform)
                    context.fill(Path(rect), with: .color(.secondary))
                }

                for item in model.furniture {
                    let rect = CGRect(x: item.position.x - item.size.width / 2,
                                      y: item.position.y - item.size.height / 2,
                                      width: item.size.width,
                                      height: item.size.height)
                        .applying(transform)
                    context.stroke(Path(rect), with: .color(.blue))
                }
            }
            .gesture(panAndZoomGestures)
        }
    }

    private var panAndZoomGestures: some Gesture {
        SimultaneousGesture(
            DragGesture().onChanged { value in
                offset.width += value.translation.width
                offset.height += value.translation.height
            },
            MagnificationGesture().onChanged { value in
                zoom = max(0.25, min(4.0, zoom * value))
            }
        )
    }
}
