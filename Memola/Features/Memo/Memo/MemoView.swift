//
//  MemoView.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/4/24.
//

import SwiftUI
import CoreData

struct MemoView: View {
    @StateObject var tool: Tool
    @StateObject var canvas: Canvas
    @StateObject var history = History()

    @State var memo: MemoObject
    @State var title: String
    @FocusState var textFieldState: Bool

    let size: CGFloat = 32

    init(memo: MemoObject) {
        self.memo = memo
        self.title = memo.title
        self._tool = StateObject(wrappedValue: Tool(object: memo.tool))
        self._canvas = StateObject(wrappedValue: Canvas(size: memo.canvas.size, canvasID: memo.canvas.objectID))
    }

    var body: some View {
        CanvasView()
            .ignoresSafeArea()
            .overlay(alignment: .trailing) {
                PenDock()
            }
            .overlay(alignment: .bottomLeading) {
                zoomControl
            }
            .disabled(textFieldState)
            .overlay(alignment: .top) {
                Toolbar(memo: memo, size: size)
            }
            .disabled(canvas.state == .loading || canvas.state == .closing)
            .overlay {
                switch canvas.state {
                case .loading:
                    loadingIndicator("Loading memo...")
                case .closing:
                    loadingIndicator("Saving memo...")
                default:
                    EmptyView()
                }
            }
            .environmentObject(tool)
            .environmentObject(canvas)
            .environmentObject(history)
    }

    @ViewBuilder
    var zoomControl: some View {
        let upperBound: CGFloat = 400
        let lowerBound: CGFloat = 10
        let zoomScale: CGFloat = (((canvas.zoomScale - canvas.minimumZoomScale) * (upperBound - lowerBound) / (canvas.maximumZoomScale - canvas.minimumZoomScale)) + lowerBound).rounded()
        let zoomScales: [Int] = [400, 200, 100, 75, 50, 25, 10]
        if !canvas.locksCanvas {
            Menu {
                ForEach(zoomScales, id: \.self) { scale in
                    Button {
                        let zoomScale = ((CGFloat(scale) - lowerBound) * (canvas.maximumZoomScale - canvas.minimumZoomScale) / (upperBound - lowerBound)) + canvas.minimumZoomScale
                        canvas.zoomPublisher.send(zoomScale)
                    } label: {
                        Label {
                            Text(scale, format: .percent)
                        } icon: {
                            if CGFloat(scale) == zoomScale {
                                Image(systemName: "checkmark")
                            }
                        }
                        .font(.headline)
                    }
                }
            } label: {
                Text(zoomScale / 100, format: .percent)
                    .frame(width: 45)
                    .font(.subheadline)
                    .padding(.horizontal, size / 2.5)
                    .frame(height: size)
                    .background(.regularMaterial)
                    .clipShape(.rect(cornerRadius: 8))
                    .padding(10)
            }
            .transition(.move(edge: .bottom).combined(with: .blurReplace))
        }
    }

    func loadingIndicator(_ title: String) -> some View {
        ProgressView {
            Text(title)
        }
        .progressViewStyle(.circular)
        .padding(20)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}