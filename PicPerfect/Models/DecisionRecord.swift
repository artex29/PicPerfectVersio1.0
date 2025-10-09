//
//  DecisionRecord.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 10/1/25.
//

import SwiftUI

struct DecisionRecord: Identifiable {
    let id = UUID()
    let action: DecisionActions      // .keep o .delete
    let image: ImageInfo
    let originalGroupIndex: Int      // índice del grupo ANTES de remover
    let originalImageIndex: Int      // posición dentro del grupo ANTES de remover
    let originalGroupIds: [String]   // ids de TODAS las imágenes del grupo ANTES de remover
    let category: PhotoGroupCategory
   
}


