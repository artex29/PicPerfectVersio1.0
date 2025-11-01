//
//  Enums.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 9/23/25.
//

import SwiftUI

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

enum PhotoGroupCategory: String, CaseIterable, Codable {
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
            return LocalizedStringKey("duplicatePhotos").stringValue
        case .similars:
            return LocalizedStringKey("similarPhotos").stringValue
        case .blurry:
            return LocalizedStringKey("blurryPhotos").stringValue
        case .exposure:
            return LocalizedStringKey("exposureIssues").stringValue
        case .faces:
            return LocalizedStringKey("closedEyesBadFraming").stringValue
        case .orientation:
            return LocalizedStringKey("orientationIssues").stringValue
        case .screenshots:
            return LocalizedStringKey("screenshots").stringValue
        }
    }
    
    var icon: Image {
        switch self {
        case .duplicates:
            return Image(.duplicatesIcon)
        case .similars:
            return Image(.similarsIcon)
        case .blurry:
            return Image(.blurryIcon)
        case .exposure:
            return Image(.exposureIcon)
        case .faces:
            return Image(.closedEyesIcon)
        case .orientation:
           return Image("")
        case .screenshots:
            return Image(.screenshotsIcon)
        }
    }
    
    var photoAnalysisKey: String {
        "analyzedPhotoRecords_\(self.rawValue)"
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
            return LocalizedStringKey("startingAnalysis").stringValue
        case .duplicates:
            return LocalizedStringKey("detectingDuplicates").stringValue
        case .similars:
            return LocalizedStringKey("findingSimilarPhotos").stringValue
        case .blurry:
            return LocalizedStringKey("analyzingBlurriness").stringValue
        case .exposure:
            return LocalizedStringKey("checkingExposureLevels").stringValue
        case .faces:
            return LocalizedStringKey("detectingClosedEyes").stringValue
        case .orientation:
            return LocalizedStringKey("assessingOrientation").stringValue
        case .screenshots:
            return LocalizedStringKey("identifyingScreenshots").stringValue
        case .done:
            return LocalizedStringKey("analysisComplete").stringValue
        }
    }
}
