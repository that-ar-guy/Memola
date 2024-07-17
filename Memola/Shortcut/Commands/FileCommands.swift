//
//  FileCommands.swift
//  Memola
//
//  Created by Dscyre Scotti on 7/12/24.
//

import SwiftUI

struct FileCommands: Commands {
    @Environment(\.shortcut) private var shortcut
    @FocusedValue(\.activeSceneKey) private var appScene

    @ObservedObject private var application: Application

    init(application: Application) {
        self.application = application
    }

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            #if os(macOS)
            if appScene == nil {
                Button {
                    application.openWindow(for: .dashboard)
                } label: {
                    Text("Open Dashboard")
                }
                .keyboardShortcut("m", modifiers: [.command])
            }
            #endif
            if appScene == .memos {
                Button {
                    shortcut.trigger(.newMemo)
                } label: {
                    Text("New Memo")
                }
                .keyboardShortcut("n", modifiers: [.command])
            }
        }
    }
}
