//
//  PenStyle.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/4/24.
//

import MetalKit
import Foundation

protocol PenStyle {
    var icon: (base: String, tip: String?) { get }
    var textureName: String { get }
    var thinkness: (min: CGFloat, max: CGFloat) { get }
    var color: [CGFloat] { get }
    var stepRate: CGFloat { get }
    var generator: any StrokeGenerator { get }
}

extension PenStyle {
    @discardableResult
    func loadTexture(on device: MTLDevice) -> MTLTexture? {
        Textures.createPenTexture(with: textureName, on: device)
    }
}