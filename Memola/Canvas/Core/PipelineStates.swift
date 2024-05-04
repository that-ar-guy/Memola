//
//  PipelineStates.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/4/24.
//

import MetalKit
import Foundation

struct PipelineStates {
    static func createGridPipelineState(from renderer: Renderer, pixelFormat: MTLPixelFormat? = nil) -> MTLRenderPipelineState? {
        let device = renderer.device
        let library = renderer.library
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = library.makeFunction(name: "vertex_grid")
        pipelineDescriptor.fragmentFunction = library.makeFunction(name: "fragment_grid")
        pipelineDescriptor.colorAttachments[0].pixelFormat = pixelFormat ?? renderer.pixelFormat
        pipelineDescriptor.label = "Grid Pipeline State"

        let attachment = pipelineDescriptor.colorAttachments[0]
        attachment?.isBlendingEnabled = true
        attachment?.rgbBlendOperation = .add
        attachment?.sourceRGBBlendFactor = .one
        attachment?.destinationRGBBlendFactor = .oneMinusSourceAlpha
        attachment?.alphaBlendOperation = .add
        attachment?.sourceAlphaBlendFactor = .sourceAlpha
        attachment?.destinationAlphaBlendFactor = .oneMinusSourceAlpha

        return try? device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }

    static func createGraphicPipelineState(from renderer: Renderer, pixelFormat: MTLPixelFormat? = nil) -> MTLRenderPipelineState? {
        let device = renderer.device
        let library = renderer.library
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = library.makeFunction(name: "vertex_graphic")
        pipelineDescriptor.fragmentFunction = library.makeFunction(name: "fragment_graphic")
        pipelineDescriptor.colorAttachments[0].pixelFormat = pixelFormat ?? renderer.pixelFormat
        pipelineDescriptor.label = "Graphic Pipeline State"

        let attachment = pipelineDescriptor.colorAttachments[0]
        attachment?.isBlendingEnabled = true
        attachment?.rgbBlendOperation = .add
        attachment?.sourceRGBBlendFactor = .sourceAlpha
        attachment?.destinationRGBBlendFactor = .oneMinusSourceAlpha
        attachment?.alphaBlendOperation = .add
        attachment?.sourceAlphaBlendFactor = .one
        attachment?.destinationAlphaBlendFactor = .oneMinusSourceAlpha

        return try? device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }

    static func createStrokePipelineState(from renderer: Renderer, pixelFormat: MTLPixelFormat? = nil) -> MTLRenderPipelineState? {
        let device = renderer.device
        let library = renderer.library
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = library.makeFunction(name: "vertex_stroke")
        pipelineDescriptor.fragmentFunction = library.makeFunction(name: "fragment_stroke")
        pipelineDescriptor.colorAttachments[0].pixelFormat = pixelFormat ?? renderer.pixelFormat
        pipelineDescriptor.label = "Stroke Pipeline State"

        let attachment = pipelineDescriptor.colorAttachments[0]
        attachment?.isBlendingEnabled = true
        attachment?.rgbBlendOperation = .add
        attachment?.sourceRGBBlendFactor = .sourceAlpha
        attachment?.destinationRGBBlendFactor = .oneMinusSourceAlpha
        attachment?.alphaBlendOperation = .add
        attachment?.sourceAlphaBlendFactor = .one
        attachment?.destinationAlphaBlendFactor = .oneMinusSourceAlpha

        return try? device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }

    static func createEraserPipelineState(from renderer: Renderer, pixelFormat: MTLPixelFormat? = nil) -> MTLRenderPipelineState? {
        let device = renderer.device
        let library = renderer.library
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = library.makeFunction(name: "vertex_stroke")
        pipelineDescriptor.fragmentFunction = library.makeFunction(name: "fragment_stroke")
        pipelineDescriptor.colorAttachments[0].pixelFormat = pixelFormat ?? renderer.pixelFormat
        pipelineDescriptor.label = "Eraser Pipeline State"

        let attachment = pipelineDescriptor.colorAttachments[0]
        attachment?.isBlendingEnabled = true
        attachment?.rgbBlendOperation = .add
        attachment?.sourceRGBBlendFactor = .sourceAlpha
        attachment?.destinationRGBBlendFactor = .one
        attachment?.alphaBlendOperation = .reverseSubtract
        attachment?.sourceAlphaBlendFactor = .sourceAlpha
        attachment?.destinationAlphaBlendFactor = .oneMinusSourceAlpha

        return try? device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }

    static func createViewPortPipelineState(from renderer: Renderer, pixelFormat: MTLPixelFormat? = nil, isUpdate: Bool = false) -> MTLRenderPipelineState? {
        var label: String
        var vertexName: String
        if isUpdate {
            label = "View Port Update Pipeline State"
            vertexName = "vertex_viewport_update"
        } else {
            label = "View Port Pipeline State"
            vertexName = "vertex_viewport"
        }
        let device = renderer.device
        let library = renderer.library
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = library.makeFunction(name: vertexName)
        pipelineDescriptor.fragmentFunction = library.makeFunction(name: "fragment_viewport")
        pipelineDescriptor.colorAttachments[0].pixelFormat = pixelFormat ?? renderer.pixelFormat
        pipelineDescriptor.label = label

        let attachment = pipelineDescriptor.colorAttachments[0]
        attachment?.isBlendingEnabled = true
        attachment?.rgbBlendOperation = .add
        attachment?.sourceRGBBlendFactor = .sourceAlpha
        attachment?.destinationRGBBlendFactor = .oneMinusSourceAlpha
        attachment?.alphaBlendOperation = .add
        attachment?.sourceAlphaBlendFactor = .one
        attachment?.destinationAlphaBlendFactor = .oneMinusSourceAlpha

        return try? device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }

    static func createCachePipelineState(from renderer: Renderer) -> MTLComputePipelineState? {
        let device = renderer.device
        let library = renderer.library
        guard let function = library.makeFunction(name: "copy_texture_viewport") else {
            return nil
        }
        return try? device.makeComputePipelineState(function: function)
    }
}