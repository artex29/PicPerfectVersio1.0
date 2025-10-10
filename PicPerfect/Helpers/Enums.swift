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

enum PhotoGroupCategory: String {
    case duplicates
    case similars
    case blurry
    case exposure
    case faces
    case orientation
    case screenshots
  
    var displayName: String {
        switch self {
        case .duplicates:
            return "Duplicate Photos"
        case .similars:
            return "Similar Photos"
        case .blurry:
            return "Blurry Photos"
        case .exposure:
            return "Exposure Issues"
        case .faces:
            return "Closed Eyes / Blurry Faces"
        case .orientation:
            return "Orientation Issues"
        case .screenshots:
            return "Screenshots"
        }
    }
}

enum AnalysisProgress: String {
    case starting, duplicates, similars, blurry, exposure, faces, orientation, screenshots, done
    
    var percentage: Double {
        switch self {
        case .starting:
            return 0.0
        case .duplicates:
            return 0.3
        case .similars:
            return 0.4
        case .blurry:
            return 0.5
        case .exposure:
            return 0.65
        case .faces:
            return 0.8
        case .orientation:
            return 0.9
        case .screenshots:
            return 0.95
        case .done:
            return 1.0
        }
    }
    
    var description: String {
        switch self {
        case .starting:
            return "Starting Analysis"
        case .duplicates:
            return "Detecting Duplicates"
        case .similars:
            return "Finding Similar Photos"
        case .blurry:
            return "Analyzing for Blurriness"
        case .exposure:
            return "Checking Exposure Levels"
        case .faces:
            return "Detecting closed eyes"
        case .orientation:
            return "Assessing Orientation"
        case .screenshots:
            return "Identifying Screenshots"
        case .done:
            return "Analysis Complete"
        }
    }
}
