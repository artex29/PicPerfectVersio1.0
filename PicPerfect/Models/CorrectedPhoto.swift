//
//  CorrectedPhoto.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 8/16/25.
//
import Foundation
import SwiftUI
import Photos


struct CorrectedPhoto: Identifiable {
    let id = UUID()
    let correctedImage: PPImage
    var isSelected: Bool = true
}
