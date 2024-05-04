//
//  StrokeRenderPass.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/4/24.
//

import MetalKit
import Foundation

class StrokeRenderPass: RenderPass {
    var label: String = "Stroke Render Pass"

    var descriptor: MTLRenderPassDescriptor?
    weak var graphicDescriptor: MTLRenderPassDescriptor?

    var strokePipelineState: MTLRenderPipelineState?
    weak var graphicPipelineState: MTLRenderPipelineState?

    var stroke: Stroke?
    var strokeTexture: MTLTexture?

    init(renderer: Renderer) {
        descriptor = MTLRenderPassDescriptor()
        strokePipelineState = PipelineStates.createStrokePipelineState(from: renderer)
    }

    func resize(on view: MTKView, to size: CGSize, with renderer: Renderer) {
        guard size != .zero else { return }
        strokeTexture = Textures.createStrokeTexture(from: renderer, size: size, pixelFormat: view.colorPixelFormat)
    }

    func draw(on canvas: Canvas, with renderer: Renderer) {
        guard let descriptor else { return }

        guard let strokeTexture else { return }
        descriptor.colorAttachments[0].texture = strokeTexture
        descriptor.colorAttachments[0].clearColor = MTLClearColor(red: 1, green: 1, blue: 1, alpha: 0)
        descriptor.colorAttachments[0].loadAction = .clear
        descriptor.colorAttachments[0].storeAction = .store

        guard let commandBuffer = renderer.commandQueue.makeCommandBuffer() else { return }
        commandBuffer.label = "Stroke Command Buffer"

        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else { return }
        renderEncoder.label = label

        guard let strokePipelineState else { return }
        renderEncoder.setRenderPipelineState(strokePipelineState)

        canvas.setUniformsBuffer(device: renderer.device, renderEncoder: renderEncoder)
        stroke?.draw(device: renderer.device, renderEncoder: renderEncoder)

        renderEncoder.endEncoding()
        commandBuffer.commit()

        drawStrokeTexture(on: canvas, with: renderer)
    }

    func drawStrokeTexture(on canvas: Canvas, with renderer: Renderer) {
        guard let stroke else { return }
        guard let graphicDescriptor, let graphicPipelineState else { return }

        guard let commandBuffer = renderer.commandQueue.makeCommandBuffer() else { return }
        commandBuffer.label = "Graphic Command Buffer"
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: graphicDescriptor) else { return }
        renderEncoder.label = "Graphic Render Pass"
        renderEncoder.setRenderPipelineState(graphicPipelineState)

        renderEncoder.setFragmentTexture(strokeTexture, index: 0)
        var uniforms = GraphicUniforms(color: stroke.color)
        let uniformsBuffer = renderer.device.makeBuffer(bytes: &uniforms, length: MemoryLayout<Uniforms>.size)
        renderEncoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 11)
        canvas.renderGraphic(device: renderer.device, renderEncoder: renderEncoder)
        renderEncoder.endEncoding()
        commandBuffer.commit()
    }
}