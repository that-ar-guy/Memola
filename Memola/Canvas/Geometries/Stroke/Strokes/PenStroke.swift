//
//  PenStroke.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/4/24.
//

import MetalKit
import CoreData
import Foundation

final class PenStroke: @unchecked Sendable {
    var object: StrokeObject?
    var bounds: [CGFloat]
    var color: [CGFloat]
    var style: Int16
    var createdAt: Date
    var thickness: CGFloat
    var quads: [Quad]
    var penStyle: Style

    init(object: StrokeObject) {
        self.object = object
        self.bounds = object.bounds
        self.color = object.color
        self.style = object.style
        self.createdAt = object.createdAt
        self.thickness = object.thickness
        self.quads = []
        self.penStyle = Style(rawValue: style) ?? .marker
    }

    init(
        bounds: [CGFloat],
        color: [CGFloat],
        style: Int16,
        createdAt: Date,
        thickness: CGFloat,
        quads: [Quad] = []
    ) {
        self.bounds = bounds
        self.color = color
        self.style = style
        self.createdAt = createdAt
        self.thickness = thickness
        self.quads = quads
        self.penStyle = Style(rawValue: style) ?? .marker
    }

    var batchIndex: Int = 0
    var quadIndex: Int = -1
    var keyPoints: [CGPoint] = []

    let movingAverage = MovingAverage(windowSize: 3)

    var texture: MTLTexture?
    var indexBuffer: MTLBuffer?
    var vertexBuffer: MTLBuffer?

    var isEmpty: Bool { quads.isEmpty }
    var strokeBounds: CGRect {
        let x = bounds[0]
        let y = bounds[1]
        let width = bounds[2] - x
        let height = bounds[3] - y
        return CGRect(x: x, y: y, width: width, height: height)
    }

    func isVisible(in bounds: CGRect) -> Bool {
        bounds.contains(strokeBounds) || bounds.intersects(strokeBounds)
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

extension PenStroke {
    func loadQuads() {
        guard let object else { return }
        quads = object.quads.compactMap { quad in
            guard let quad = quad as? QuadObject else { return nil }
            return Quad(object: quad)
        }
    }

    func loadQuads(from object: StrokeObject) {
        quads = object.quads.compactMap { quad in
            guard let quad = quad as? QuadObject else { return nil }
            return Quad(object: quad)
        }
    }

    func addQuad(at point: CGPoint, rotation: CGFloat, shape: QuadShape) {
        let quad = Quad(
            origin: point,
            size: thickness,
            rotation: rotation,
            shape: shape.rawValue,
            color: color
        )
        quads.append(quad)
    }

    func removeQuads(from index: Int) {
        let dropCount = quads.endIndex - max(1, index)
        quads.removeLast(dropCount)
        let quads = Array(quads[batchIndex..<index])
        batchIndex = index
        saveQuads(for: quads)
    }

    func saveQuads(for quads: [Quad]) {
        var topLeft: CGPoint = CGPoint(x: bounds[0], y: bounds[1])
        var bottomRight: CGPoint = CGPoint(x: bounds[2], y: bounds[3])
        withPersistence(\.backgroundContext) { [weak self, object] context in
            guard let self else { return }
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
                topLeft.x = min(quad.originX, topLeft.x)
                topLeft.y = min(quad.originY, topLeft.y)
                bottomRight.x = max(quad.originX, bottomRight.x)
                bottomRight.y = max(quad.originY, bottomRight.y)
            }
            bounds = [topLeft.x, topLeft.y, bottomRight.x, bottomRight.y]
            object?.bounds = bounds
        }
    }
}

extension PenStroke: Drawable {
    func prepare(device: MTLDevice) {
        if texture == nil {
            texture = penStyle.anyPenStyle.loadTexture(on: device)
        }
    }

    func draw(device: MTLDevice, renderEncoder: MTLRenderCommandEncoder) {
        guard !isEmpty, let indexBuffer else { return }
        prepare(device: device)
        renderEncoder.setFragmentTexture(texture, index: 0)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.drawIndexedPrimitives(
            type: .triangle,
            indexCount: quads.endIndex * 6,
            indexType: .uint32,
            indexBuffer: indexBuffer,
            indexBufferOffset: 0
        )
        self.vertexBuffer = nil
        self.indexBuffer = nil
    }
}

extension PenStroke {
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