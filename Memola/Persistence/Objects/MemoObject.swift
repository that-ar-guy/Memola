//
//  MemoObject.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/11/24.
//

import CoreData
import Foundation

@objc(MemoObject)
final class MemoObject: NSManagedObject, Identifiable {
    @NSManaged var data: Data
    @NSManaged var title: String
    @NSManaged var createdAt: Date
    @NSManaged var updatedAt: Date
    @NSManaged var deletedAt: Date?
    @NSManaged var isFavorite: Bool
    @NSManaged var isTrash: Bool
    @NSManaged var preview: Data?
    @NSManaged var tool: ToolObject
    @NSManaged var canvas: CanvasObject

    var files: [PhotoFileObject] {
        canvas.graphicContext.files.compactMap { $0 as? PhotoFileObject }
    }
}
