//
//  Enums.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 9/23/25.
//

enum ImageType: String {
    case face, object, horizon, unknown
}

enum DetectedOrientation: String, CaseIterable {
    case up, rotatedRight, upsideDown, rotatedLeft
}

enum ExposureCategory {
    case underexposed   // Too dark
    case overexposed    // Too bright / blown out
    case normal         // Properly exposed
}

enum FaceIssue {
    case eyesClosed
    case blurry
    case badFraming
}
