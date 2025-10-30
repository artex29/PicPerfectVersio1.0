//
//  FaceIssue.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 10/3/25.
//





import Vision
import Photos

#if os(macOS)
import AppKit
#else
import UIKit
#endif

final class FaceQualityService {
    
    static func detectBadFaceOnImage(_ image: PPImage, asset: PHAsset) async -> ImageInfo? {
        let issues = analyzeFaces(in: image)
        if !issues.isEmpty {
            var info = ImageInfo(isIncorrect: true, image: image, asset: asset, fileSizeInMB: asset.fileSizeInMB)
            info.source = "faceQualityService"
            info.faceIssues = issues
            return info
        }
        return nil
    }
    
    /// Detect face issues in a list of PHAssets
    static func detectBadFaces(
        assets: [PHAsset],
        limit: Int = 100
    ) async -> [ImageInfo] {
        var badFaces: [ImageInfo] = []
        
        for (index, asset) in assets.enumerated() {
            guard index < limit else { break }
            
            if let uiImage = await Service.requestImage(for: asset,
                                                        size: CGSize(width: 1024, height: 1024)) {
                let issues = analyzeFaces(in: uiImage)
                if !issues.isEmpty {
                    var info = ImageInfo(isIncorrect: true, image: uiImage, asset: asset)
                    // Store issues description in `source` for debugging
                    info.source = "faceQualityService"
                    info.faceIssues = issues
                    badFaces.append(info)
                }
            }
        }
        
        return badFaces
    }
    
    /// Analyze face quality issues in a single image
    private static func analyzeFaces(in image: PPImage,
                             eyeClosureThreshold: Float = 0.15,
                             blurThreshold: Float = 0.3,
                             minFaceCoverage: CGFloat = 0.1) -> [FaceIssue] {
        #if os(iOS)
        guard let cgImage = image.cgImage else { return [] }
        #elseif os(macOS)
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return [] }
        #endif
        var issues: [FaceIssue] = []
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        // 1. Detect faces
        let faceRequest = VNDetectFaceRectanglesRequest()
        try? handler.perform([faceRequest])
        
        guard let observations = faceRequest.results,
              let firstFace = observations.first else {
            return issues
        }
        
//        // 2. Check blur/quality
//        let qualityRequest = VNDetectFaceCaptureQualityRequest()
//        try? handler.perform([qualityRequest])
//        if let q = (qualityRequest.results?.first as? VNFaceObservation)?.faceCaptureQuality {
//            if q < blurThreshold {
//                issues.append(.blurry)
//            }
//        }
        
        // 3. Check eyes closed
        let landmarkRequest = VNDetectFaceLandmarksRequest()
        try? handler.perform([landmarkRequest])
        if let landmarks = (landmarkRequest.results?.first as? VNFaceObservation)?.landmarks {
            if let leftEye = landmarks.leftEye, let rightEye = landmarks.rightEye {
                // Compute average eye "height"
                let avgOpen = (eyeOpenness(leftEye) + eyeOpenness(rightEye)) / 2
                if avgOpen < eyeClosureThreshold {
                    issues.append(.eyesClosed)
                }
            }
        }
        
        // 4. Check framing
        let faceBox = firstFace.boundingBox
        let area = faceBox.width * faceBox.height
        if area < minFaceCoverage {
            issues.append(.badFraming) // too small
        }
        if faceBox.minX <= 0.02 || faceBox.maxX >= 0.98 ||
            faceBox.minY <= 0.02 || faceBox.maxY >= 0.98 {
            issues.append(.badFraming) // cropped at edges
        }
        
        return issues
    }
    
    /// Helper to measure eye openness from landmarks
    private static func eyeOpenness(_ region: VNFaceLandmarkRegion2D) -> Float {
        guard region.pointCount >= 6 else { return 1.0 }
        // Approximate openness = vertical range of eye points
        let ys = region.normalizedPoints.map { $0.y }
        return Float((ys.max() ?? 0) - (ys.min() ?? 0))
    }
}
