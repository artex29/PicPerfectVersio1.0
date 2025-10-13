//
//  ExposureCategory.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 10/3/25.
//


//import UIKit
import Photos
import CoreImage
#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif


final class ExposureService {
    
    //Scan a single Image
    static func detectExposureIssueOnImage(image: PPImage,
                                           asset: PHAsset,
                                           darkTreshold: Float = 0.2,
                                           brightTreshold: Float = 0.8) async -> ImageInfo? {
        
        let result = analyzeExposure(for: image, darkThreshold: darkTreshold, brightThreshold: brightTreshold)
        
        if result != .normal {
            var info = ImageInfo(isIncorrect: true, image: image, asset: asset, exposure: result)
            info.source = "exposureService"
            return info
        }
        
        return nil
    }
    
    /// Escanea múltiples assets y devuelve solo los que están mal expuestos
    static func detectExposureIssues(
        assets: [PHAsset],
        darkThreshold: Float = 0.2,
        brightThreshold: Float = 0.8,
        limit: Int = 100
    ) async -> [ImageInfo] {
        var problematic: [ImageInfo] = []
        
        for (index, asset) in assets.enumerated() {
            guard index < limit else { break }
            
            if let uiImage = await Service.requestImage(for: asset,
                                                        size: CGSize(width: 1024, height: 1024)) {
                let result = analyzeExposure(for: uiImage,
                                             darkThreshold: darkThreshold,
                                             brightThreshold: brightThreshold)
                if result != .normal {
                    let info = ImageInfo(isIncorrect: true, image: uiImage, asset: asset, exposure: result)
                    problematic.append(info)
                }
            }
        }
        
        return problematic
    }
    
    /// Detecta si una imagen está subexpuesta (oscura) o sobreexpuesta (quemada)
    private static func analyzeExposure(for image: PPImage,
                                darkThreshold: Float = 0.2,
                                brightThreshold: Float = 0.8,
                                tolerance: Float = 0.7) -> ExposureCategory {
        
        #if os(iOS)
        guard let cgImage = image.cgImage else { return .normal }
        #elseif os(macOS)
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return .normal }
        #endif
        
        let ciImage = CIImage(cgImage: cgImage)
        let extent = ciImage.extent
        
        let filter = CIFilter(name: "CIAreaAverage",
                              parameters: [kCIInputImageKey: ciImage,
                                           kCIInputExtentKey: CIVector(cgRect: extent)])
        
        let context = CIContext()
        guard let output = filter?.outputImage,
              let bitmap = context.createCGImage(output, from: output.extent) else {
            return .normal
        }
        
        var avgColor: [UInt8] = [0, 0, 0, 0]
        let context2 = CGContext(data: &avgColor,
                                 width: 1,
                                 height: 1,
                                 bitsPerComponent: 8,
                                 bytesPerRow: 4,
                                 space: CGColorSpaceCreateDeviceRGB(),
                                 bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        context2?.draw(bitmap, in: CGRect(x: 0, y: 0, width: 1, height: 1))
        
        let r = Float(avgColor[0]) / 255.0
        let g = Float(avgColor[1]) / 255.0
        let b = Float(avgColor[2]) / 255.0
        let brightness = (r + g + b) / 3.0
        
        if brightness < darkThreshold {
            return .underexposed
        } else if brightness > brightThreshold {
            return .overexposed
        } else {
            return .normal
        }
    }
}
