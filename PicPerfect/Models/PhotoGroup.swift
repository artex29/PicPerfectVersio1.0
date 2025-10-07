//
//  Untitled.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 10/6/25.
//

import Foundation

struct PhotoGroup: Identifiable, Hashable {
    let id = UUID()
    let images: [ImageInfo]
    let score: Float?    // optional, for duplicates similarity or blur avg
    let category: PhotoGroupCategory // e.g. "Duplicates", "Blurry", "Exposure", "Faces"
}
