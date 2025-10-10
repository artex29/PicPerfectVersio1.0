//
//  ConfirmationAction.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 10/9/25.
//

import SwiftUI


struct ConfirmationAction: Identifiable, Hashable {
    var id = UUID()
    var imageInfo: ImageInfo
    var action: DecisionActions
    var category: PhotoGroupCategory
}
