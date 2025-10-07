//
//  ImageInfo.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 10/2/25.
//

import SwiftUI
import Photos


struct PredictedResult: Identifiable {
    var id: String = UUID().uuidString
    var image: UIImage
    var orientation: DetectedOrientation
    var confidence: Float
}

struct ImageInfo: Hashable, Identifiable {
    var isIncorrect: Bool
    var image: UIImage
    var asset: PHAsset?
    var summary: PhotoSummary? = nil
    var imageType: ImageType? = nil
    var orientation: DetectedOrientation? = nil
    var rotationAngle: CGFloat? = nil
    var confidence: Float? = nil
    var source: String? = nil
    
    // Exposure analysis result (dark, bright, or normal)
    var exposure: ExposureCategory? = nil
    
    // Blur score (sharpness metric).
    // Lower values = blurry, higher values = sharp.
    var blurScore: Float? = nil
    
    // Detected face-related issues
    var faceIssues: [FaceIssue]? = nil
    
    var id: String {
        let identifier = asset?.localIdentifier
        if identifier?.isEmpty == true || identifier == "(null)/L0/001" {
            if identifier == "(null)/L0/001" {
                return "\(image.size)\(image.scale)\(image.imageOrientation)\(image.isPortrait)"
            } else {
                return UUID().uuidString
            }
        }
        return identifier ?? UUID().uuidString
    }
    
    static func == (lhs: ImageInfo, rhs: ImageInfo) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
