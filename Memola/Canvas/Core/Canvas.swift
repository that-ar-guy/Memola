//
//  Canvas.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/4/24.
//

import Combine
import CoreData
import MetalKit
import Foundation

final class Canvas: NSObject, ObservableObject, Identifiable, Codable, GraphicContextDelegate {
    let size: CGSize
    let maximumZoomScale: CGFloat = 30
    let minimumZoomScale: CGFloat = 3.1

    var transform: simd_float4x4 = .init()

    var uniformsBuffer: MTLBuffer?

    let gridContext = GridContext()
    var graphicContext = GraphicContext()
    let viewPortContext = ViewPortContext()

    var clipBounds: CGRect = .zero
    var zoomScale: CGFloat = .zero

//    weak var board: BoardObject?
    var graphicLoader: (() throws -> GraphicContext)?

    @Published var state: State = .initial
    lazy var didUpdate = PassthroughSubject<Void, Never>()

    init(size: CGSize = .init(width: 8_000, height: 8_000)) {
        self.size = size
    }

    enum CodingKeys: CodingKey {
        case size
        case graphicContext
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.size = try container.decode(CGSize.self, forKey: .size)
        self.graphicLoader = { try container.decode(GraphicContext.self, forKey: .graphicContext) }
    }
}

// MARK: - Actions
extension Canvas {
    func load() {
        guard let graphicLoader else { return }
        Task(priority: .high) { [unowned self, graphicLoader] in
            await MainActor.run {
                self.state = .loading
            }
            do {
                let graphicContext = try graphicLoader()
                graphicContext.delegate = self
                await MainActor.run {
                    self.graphicContext = graphicContext
                    self.state = .loaded
                }
            } catch {
                NSLog("[SketchNote] - \(error.localizedDescription)")
                await MainActor.run {
                    self.state = .failed
                }
            }
        }
    }

    func save(on managedObjectContext: NSManagedObjectContext) async {
//        guard let board else { return }
//        do {
//            board.data = try JSONEncoder().encode(self)
//            board.updatedAt = Date()
//            try managedObjectContext.save()
//        } catch {
//            NSLog("[SketchNote] - \(error.localizedDescription)")
//        }
    }

    func listen(on managedObjectContext: NSManagedObjectContext) {
        Task(priority: .background) { [unowned self] in
            for await _ in didUpdate.values {
                await save(on: managedObjectContext)
            }
        }
    }
}

// MARK: - Dimension
extension Canvas {
    func updateTransform(on drawingView: DrawingView) {
        let bounds = CGRect(origin: .zero, size: size)
        let renderView = drawingView.renderView
        let targetRect = drawingView.convert(drawingView.bounds, to: renderView)
        let transform1 = bounds.transform(to: targetRect)
        let transform2 = renderView.bounds.transform(to: CGRect(x: -1.0, y: -1.0, width: 2.0, height: 2.0))
        let transform3 = CGAffineTransform.identity.translatedBy(x: 0, y: 1).scaledBy(x: 1, y: -1).translatedBy(x: 0, y: 1)
        self.transform = simd_float4x4(transform1 * transform2 * transform3)
    }

    func updateClipBounds(_ scrollView: UIScrollView, on drawingView: DrawingView) {
        let ratio = drawingView.ratio
        let bounds = scrollView.convert(scrollView.bounds, to: drawingView)
        clipBounds = CGRect(origin: bounds.origin.muliply(by: ratio), size: bounds.size.multiply(by: ratio))
    }
}

// MARK: - Zoom Scale
extension Canvas {
    func setZoomScale(_ zoomScale: CGFloat) {
        self.zoomScale = zoomScale
    }
}

// MARK: - Graphic Context
extension Canvas {
    func beginTouch(at point: CGPoint, pen: Pen) -> Stroke {
        graphicContext.beginStroke(at: point, pen: pen)
    }

    func moveTouch(to point: CGPoint) {
        graphicContext.appendStroke(with: point)
    }

    func endTouch(at point: CGPoint) {
        graphicContext.endStroke(at: point)
    }

    func setGraphicRenderType(_ renderType: GraphicContext.RenderType) {
        graphicContext.renderType = renderType
    }

    func getNewlyAddedStroke() -> Stroke? {
        graphicContext.strokes.last
    }
}

// MARK: - Rendering
extension Canvas {
    func renderGrid(device: MTLDevice, renderEncoder: MTLRenderCommandEncoder) {
        var uniforms = GridUniforms(
            ratio: size.width.float / 100,
            zoom: zoomScale.float,
            transform: transform
        )
        uniformsBuffer = device.makeBuffer(bytes: &uniforms, length: MemoryLayout<GridUniforms>.size)
        renderEncoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 11)
        gridContext.draw(device: device, renderEncoder: renderEncoder)
    }

    func renderGraphic(device: MTLDevice, renderEncoder: MTLRenderCommandEncoder) {
        graphicContext.draw(device: device, renderEncoder: renderEncoder)
    }

    func renderViewPort(device: MTLDevice, renderEncoder: MTLRenderCommandEncoder) {
        viewPortContext.setViewPortVertices()
        viewPortContext.draw(device: device, renderEncoder: renderEncoder)
    }

    func renderViewPortUpdate(device: MTLDevice, renderEncoder: MTLRenderCommandEncoder) {
        var uniforms = Uniforms(transform: transform)
        uniformsBuffer = device.makeBuffer(bytes: &uniforms, length: MemoryLayout<Uniforms>.size)
        renderEncoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 11)
        viewPortContext.setViewPortUpdateVertices(from: clipBounds)
        viewPortContext.draw(device: device, renderEncoder: renderEncoder)
    }

    func setUniformsBuffer(device: MTLDevice, renderEncoder: MTLRenderCommandEncoder) {
        var uniforms = Uniforms(transform: transform)
        uniformsBuffer = device.makeBuffer(bytes: &uniforms, length: MemoryLayout<Uniforms>.size)
        renderEncoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 11)
    }
}

// MARK: - State
extension Canvas {
    enum State {
        case initial
        case loading
        case loaded
        case closing
        case closed
        case failed
    }
}