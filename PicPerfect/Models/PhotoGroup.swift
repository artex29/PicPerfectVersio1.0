//
//  Untitled.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 10/6/25.
//

import Foundation
import SwiftData

struct PhotoGroup: Identifiable, Hashable {
    var id: UUID = UUID()
    var images: [ImageInfo]
    let score: Float?    // optional, for duplicates similarity or blur avg
    let category: PhotoGroupCategory // e.g. "Duplicates", "Blurry", "Exposure", "Faces"
}


@Model
class PersistentPhotoGroup {
    var id: UUID = UUID()
    var imageIds: [String] = []
    var score: Float? = nil
    var category: String = ""
    var isPending: Bool = true
    var dateSaved: Date = Date()
    
    init(id: UUID,
         imageIds: [String],
         score: Float? = nil,
         category: String,
         isPending: Bool = true,
         dateSaved: Date = Date()) {
        self.id = id
        self.imageIds = imageIds
        self.score = score
        self.category = category
        self.isPending = isPending
        self.dateSaved = dateSaved
    }
}
