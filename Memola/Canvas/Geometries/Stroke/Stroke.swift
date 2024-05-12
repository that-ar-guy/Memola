//
//  Stroke.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/4/24.
//

import MetalKit
import CoreData
import Foundation

final class Stroke: @unchecked Sendable {
    var object: StrokeObject?
    var color: [CGFloat]
    var style: Int16
    var createdAt: Date
    var thickness: CGFloat
    var quads: [Quad]

    init(object: StrokeObject) {
        self.object = object
        self.color = object.color
        self.style = object.style
        self.createdAt = object.createdAt
        self.thickness = object.thickness
        self.quads = []
    }

    init(
        color: [CGFloat],
        style: Int16,
        createdAt: Date,
        thickness: CGFloat,
        quads: [Quad] = []
    ) {
        self.color = color
        self.style = style
        self.createdAt = createdAt
        self.thickness = thickness
        self.quads = quads
    }

    var angle: CGFloat = 0
    var penStyle: Style {
        Style(rawValue: style) ?? .marker
    }

    var batchIndex: Int = 0
    var quadIndex: Int = -1
    var keyPoints: [CGPoint] = []
    var thicknessFactor: CGFloat = 0.7

    var vertexBuffer: MTLBuffer?
    var texture: MTLTexture?

    var isEmpty: Bool {
        quads.isEmpty
    }
    var isEraserPenStyle: Bool {
        penStyle == .eraser
    }

    func begin(at point: CGPoint) {
        penStyle.anyPenStyle.generator.begin(at: point, on: self)
    }

    func append(to point: CGPoint) {
        penStyle.anyPenStyle.generator.append(to: point, on: self)
    }

    func finish(at point: CGPoint) {
        penStyle.anyPenStyle.generator.finish(at: point, on: self)
        keyPoints.removeAll()
    }
}

extension Stroke {
    func loadQuads() {
        guard let object else { return }
        quads = object.quads.compactMap { quad in
            guard let quad = quad as? QuadObject else { return nil }
            return Quad(object: quad)
        }
    }

    func addQuad(at point: CGPoint, rotation: CGFloat, shape: QuadShape) -> Quad {
        let quad = Quad(
            origin: point,
            size: thickness,
            rotation: rotation,
            shape: shape.rawValue,
            color: color
        )
        quads.append(quad)
        return quad
    }

    func removeQuads(from index: Int) {
        let dropCount = quads.endIndex - max(1, index)
        quads.removeLast(dropCount)
        let quads = Array(quads[batchIndex..<index])
        batchIndex = index
        withPersistence(\.backgroundContext) { [weak self, quads] context in
            self?.saveQuads(for: quads)
        }
    }

    func saveQuads(for quads: [Quad]) {
        for _quad in quads {
            let quad = QuadObject(\.backgroundContext)
            quad.originX = _quad.originX.cgFloat
            quad.originY = _quad.originY.cgFloat
            quad.size = _quad.size.cgFloat
            quad.rotation = _quad.rotation.cgFloat
            quad.shape = _quad.shape
            quad.color = _quad.getColor()
            quad.stroke = object
            object?.quads.add(quad)
        }
    }
}

extension Stroke: Drawable {
    func prepare(device: MTLDevice) {
        if texture == nil {
            texture = penStyle.anyPenStyle.loadTexture(on: device)
        }
    }

    func draw(device: MTLDevice, renderEncoder: MTLRenderCommandEncoder) {
        guard !isEmpty else { return }
        prepare(device: device)
        renderEncoder.setFragmentTexture(texture, index: 0)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: quads.endIndex * 6)
        vertexBuffer = nil
    }
}

extension Stroke {
    enum Style: Int16 {
        case marker
        case eraser

        var anyPenStyle: any PenStyle {
            switch self {
            case .marker:
                return MarkerPenStyle.marker
            case .eraser:
                return EraserPenStyle.eraser
            }
        }
    }
}
