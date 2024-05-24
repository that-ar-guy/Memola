//
//  Toolbar.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/19/24.
//

import SwiftUI
import Foundation

struct Toolbar: View {
    @Environment(\.dismiss) var dismiss
    
    @EnvironmentObject var history: History
    @EnvironmentObject var canvas: Canvas

    @State var memo: MemoObject
    @State var title: String
    @FocusState var textFieldState: Bool

    let size: CGFloat

    init(memo: MemoObject, size: CGFloat) {
        self.memo = memo
        self.size = size
        self.title = memo.title
    }
    
    var body: some View {
        HStack(spacing: 5) {
            if !canvas.locksCanvas {
                closeButton
                titleField
            }
            Spacer()
            if !canvas.locksCanvas {
                historyControl
            }
            lockButton
        }
        .font(.subheadline)
        .padding(10)
    }

    var closeButton: some View {
        Button {
            closeMemo()
        } label: {
            Image(systemName: "xmark")
                .contentShape(.circle)
                .frame(width: size, height: size)
                .background(.regularMaterial)
                .clipShape(.rect(cornerRadius: 8))
        }
        .hoverEffect(.lift)
        .disabled(textFieldState)
        .transition(.move(edge: .top).combined(with: .blurReplace))
    }

    var titleField: some View {
        TextField("", text: $title)
            .focused($textFieldState)
            .textFieldStyle(.plain)
            .padding(.horizontal, size / 2.5)
            .frame(width: 140, height: size)
            .background(.regularMaterial)
            .clipShape(.rect(cornerRadius: 8))
            .onChange(of: textFieldState) { oldValue, newValue in
                if !newValue {
                    if !title.isEmpty {
                        memo.title = title
                    } else {
                        title = memo.title
                    }
                }
            }
            .transition(.move(edge: .top).combined(with: .blurReplace))
    }

    var historyControl: some View {
        HStack {
            Button {
                history.historyPublisher.send(.undo)
            } label: {
                Image(systemName: "arrow.uturn.backward.circle")

                    .contentShape(.circle)
            }
            .hoverEffect(.lift)
            .disabled(history.undoDisabled)
            Button {
                history.historyPublisher.send(.redo)
            } label: {
                Image(systemName: "arrow.uturn.forward.circle")
                    .contentShape(.circle)
            }
            .hoverEffect(.lift)
            .disabled(history.redoDisabled)
        }
        .frame(width: size * 2, height: size)
        .background(.regularMaterial)
        .clipShape(.rect(cornerRadius: 8))
        .disabled(textFieldState)
        .transition(.move(edge: .top).combined(with: .blurReplace))
    }

    var lockButton: some View {
        Button {
            withAnimation {
                canvas.locksCanvas.toggle()
            }
        } label: {
            ZStack {
                if canvas.locksCanvas {
                    Image(systemName: "lock.open")
                        .transition(.move(edge: .trailing).combined(with: .blurReplace))
                } else {
                    Image(systemName: "lock")
                        .transition(.move(edge: .leading).combined(with: .blurReplace))
                }
            }
            .contentShape(.circle)
            .frame(width: size, height: size)
            .background(.regularMaterial)
            .clipShape(.rect(cornerRadius: 8))
        }
        .hoverEffect(.lift)
    }

    func closeMemo() {
        DispatchQueue.global(qos: .userInitiated).async {
            DispatchQueue.main.async {
                canvas.state = .closing
            }
            withPersistenceSync(\.viewContext) { context in
                try context.saveIfNeeded()
            }
            DispatchQueue.main.async {
                canvas.state = .closed
                dismiss()
            }
        }
    }
}