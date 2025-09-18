//
//  Service.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 9/8/25.
//

import Photos
import UIKit
import MobileCoreServices

class Service {
   
    static func exifOrientation(for orientation: UIImage.Orientation) -> Int {
        switch orientation {
        case .up: return 1
        case .down: return 3
        case .left: return 8
        case .right: return 6
        case .upMirrored: return 2
        case .downMirrored: return 4
        case .leftMirrored: return 5
        case .rightMirrored: return 7
        @unknown default: return 1
        }
    }

    static func saveAndReplace(results: [ImageOrientationResult], deleteOriginals: Bool, completion: @escaping (Bool) -> Void) {
        PHPhotoLibrary.shared().performChanges({
            for result in results {
                guard let cgImage = result.image.cgImage else { continue }

                // Convertir orientación UIImage -> EXIF
                let orientationValue = exifOrientation(for: result.image.imageOrientation)

                // Crear NSData con orientación en los metadatos
                let imageData = NSMutableData()
                
                guard let destination = CGImageDestinationCreateWithData(
                    imageData,
                    UTType.jpeg.identifier as CFString, // 👈 usar el identifier
                    1,
                    nil
                ) else { continue }

                let properties: [CFString: Any] = [
                    kCGImagePropertyOrientation: orientationValue
                ]

                CGImageDestinationAddImage(destination, cgImage, properties as CFDictionary)
                CGImageDestinationFinalize(destination)

                // Guardar como nuevo asset con metadatos EXIF
                let creationRequest = PHAssetCreationRequest.forAsset()
                let options = PHAssetResourceCreationOptions()
                creationRequest.addResource(with: .photo, data: imageData as Data, options: options)
            }

            // Borrar las fotos originales
            if deleteOriginals {
                let assetsToDelete = results.map { $0.asset }
                PHAssetChangeRequest.deleteAssets(assetsToDelete as NSArray)
            }

        }) { success, error in
            if success {
                print("✅ Corrected images saved with metadata and originals deleted")
                completion(true)
            } else {
                print("❌ Error saving or deleting images: \(error?.localizedDescription ?? "unknown error")")
                completion(false)
            }
        }
    }
    
    static func requestPhotoLibraryAccessIfNeeded(completion: @escaping (Bool) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        
        switch status {
        case .authorized, .limited:
            completion(true)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
                DispatchQueue.main.async {
                    completion(newStatus == .authorized || newStatus == .limited)
                }
            }
        default:
            completion(false)
        }
    }
    
}
