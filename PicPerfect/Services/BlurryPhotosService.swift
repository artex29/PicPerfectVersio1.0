//
//  BlurryPhotosService.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 10/3/25.
//

import SwiftUI
import Vision
import CoreImage
import Photos


class BlurryPhotosService {
    
    // Detect blurriness on a single photo
    static func detectBlurriness(in image: UIImage,
                                 asset: PHAsset,
                                 laplacianThreshold: Float = 100.0,
                                 faceTreshold: Float = 0.3) async -> ImageInfo? {
        
        let isBlurry = isBlurry(image, laplacianThreshold: laplacianThreshold, faceThreshold: faceTreshold)
        
        if isBlurry.0 {
            var info = ImageInfo(isIncorrect: true, image: image, asset: asset, blurScore: isBlurry.1)
            info.source = "blurryPhotosService"
            return info
        }
        
        return nil
        
    }
    
    static func detectBlurryPhotos(
        assets: [PHAsset],
        laplacianThreshold: Float = 100.0,
        faceThreshold: Float = 0.3,
        limit: Int = 100
    ) async -> [ImageInfo] {
        var blurryImages: [ImageInfo] = []
        
        for (index, asset) in assets.enumerated() {
            guard index < limit else { break }
            
            if let uiImage = await Service.requestImage(for: asset, size: CGSize(width: 512, height: 512)) {
                
                let isBlurry = isBlurry(uiImage,
                                        laplacianThreshold: laplacianThreshold,
                                        faceThreshold: faceThreshold)
                
                if isBlurry.0 {
                    
                    let info = ImageInfo(isIncorrect: true, image: uiImage, asset: asset, blurScore: isBlurry.1)
                    blurryImages.append(info)
                }
            }
        }
        
        return blurryImages
    }
    
    private static func isBlurry(_ image: UIImage,
                                 laplacianThreshold: Float = 100.0,
                                 faceThreshold: Float = 0.3) -> (Bool, Float) {
        // 1. Si hay rostro, usar face quality
        if let quality = faceQualityScore(image) {
            print("Face Quality: \(quality)")
            return (quality < faceThreshold, quality)
        }
        
       
        // 2. Si no hay rostro, usar Laplaciano
        let variance = laplacianVariance(image)
        print("Laplacian Variance: \(variance)")
        return (variance < laplacianThreshold, variance)
    }
    
    private static func faceQualityScore(_ image: UIImage) -> Float? {
        guard let cgImage = image.cgImage else { return nil }
        
        let request = VNDetectFaceCaptureQualityRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try? handler.perform([request])
        
        if let face = request.results?.first as? VNFaceObservation {
            return face.faceCaptureQuality // 0.0 (mala) a 1.0 (buena)
        }
        return nil
    }
    
    private static func laplacianVariance(_ image: UIImage) -> Float {
        guard let ciImage = CIImage(image: image) else { return 0 }
        
        let context = CIContext()
        
        // Filtro Laplaciano (bordes)
        let weights: [CGFloat] = [
            -1, -1, -1,
            -1,  8, -1,
            -1, -1, -1
        ]
        
        guard let filter = CIFilter(name: "CIConvolution3X3",
                                    parameters: [
                                        kCIInputImageKey: ciImage,
                                        "inputWeights": CIVector(values: weights, count: 9),
                                        "inputBias": 0
                                    ]),
              let output = filter.outputImage,
              let cgImage = context.createCGImage(output, from: output.extent),
              let data = cgImage.dataProvider?.data else {
            return 0
        }
        
        let ptr = CFDataGetBytePtr(data)
        let length = CFDataGetLength(data)
        
        var mean: Float = 0
        for i in 0..<length {
            mean += Float(ptr![i])
        }
        mean /= Float(length)
        
        var variance: Float = 0
        for i in 0..<length {
            let diff = Float(ptr![i]) - mean
            variance += diff * diff
        }
        variance /= Float(length)
        
        return variance
    }
}
