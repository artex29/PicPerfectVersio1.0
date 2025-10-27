//
//  Untitled.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 10/6/25.
//

import Foundation
import SwiftData

struct PhotoGroup: Identifiable, Hashable {
    var id: String {
        images.map { $0.id }.joined(separator: "-")
    }
    var images: [ImageInfo]
    let score: Float?    // optional, for duplicates similarity or blur avg
    let category: PhotoGroupCategory // e.g. "Duplicates", "Blurry", "Exposure", "Faces"
}


@Model
class PersistentPhotoGroup {
    var id: String = UUID().uuidString
    var imageIds: [String] = []
    var score: Float? = nil
    var category: String = ""
    var isPending: Bool = true
    var dateSaved: Date = Date()
    
    init(id: String,
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
