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
    
    static func saveAndReplace(results: [ImageInfo], completion: @escaping (Bool) -> Void) {
        
        var processedIdentifiers: [String] = []
        
        for result in results {
            let asset = result.asset
            
            let identifier = asset?.localIdentifier ?? UUID().uuidString
            
            processedIdentifiers.append(identifier)

            let requestOptions = PHContentEditingInputRequestOptions()
            requestOptions.canHandleAdjustmentData = { _ in true }

            asset?.requestContentEditingInput(with: requestOptions) { input, _ in
                guard let input = input else { return }

                let output = PHContentEditingOutput(contentEditingInput: input)

                // 1. Guardar la imagen corregida en disco
                if let data = result.image.jpegData(compressionQuality: 1.0) {
                    do {
                        try data.write(to: output.renderedContentURL)
                    } catch {
                        print("❌ Error writing corrected image: \(error)")
                        completion(false)
                        return
                    }
                }

                // 2. Crear JSON con los metadatos de la edición
                let adjustmentInfo: [String: Any?] = [
                    "isIncorrect": result.isIncorrect,
                    "imageType": result.imageType?.rawValue,
                    "orientation": result.orientation?.rawValue,
                    "rotationAngle": result.rotationAngle,
                    "confidence": result.confidence,
                    "source": result.source,
                    "timestamp": Date().timeIntervalSince1970,
                    "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
                ]

                let jsonData = try? JSONSerialization.data(withJSONObject: adjustmentInfo.compactMapValues { $0 }, options: [])

                // 3. Guardar JSON en adjustmentData
                let adjustmentData = PHAdjustmentData(
                    formatIdentifier: "net.artexcomputer.PicPerfect",
                    formatVersion: "1.0",
                    data: jsonData ?? Data()
                )
                output.adjustmentData = adjustmentData

                // 4. Guardar cambios en el asset
                PHPhotoLibrary.shared().performChanges({
                    let request = PHAssetChangeRequest(for: asset ?? PHAsset())
                    request.contentEditingOutput = output
                }) { success, error in
                    if success {
                        print("✅ Asset replaced with non-destructive edit")
                       
                    } else {
                        print("❌ Error saving edit: \(error?.localizedDescription ?? "unknown error")")
                        completion(false)
                    }
                }
            }
        }
        
        PhotoAnalysisCloudCache.saveProcessedPhotos(processedIdentifiers)
        completion(true)
    }
    
    static func getLibraryAssets() async -> [PHAsset] {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        
       // let allPhotos = PHAsset.fetchAssets(with: fetchOptions)
        
        let assets:PHFetchResult<PHAsset> = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        
        return assets.objects(at: IndexSet(0..<assets.count))
    }


    
    static func deleteAssets(_ assets: [PHAsset]) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets(assets as NSArray)
        }) { success, error in
            if success {
                print("🗑️ Original photo deleted")
            } else if let error = error {
                print("❌ Error deleting photo: \(error.localizedDescription)")
            }
        }
    }
    
    static func requestImage(for asset: PHAsset, size: CGSize = CGSize(width: 1024, height: 1024)) async -> UIImage? {
        await withCheckedContinuation { continuation in
            
            let options = PHImageRequestOptions()
            options.isSynchronous = true
            options.deliveryMode = .highQualityFormat
            options.resizeMode = .fast
            
            PHImageManager.default().requestImage(for: asset,
                                                  targetSize: size,
                                                  contentMode: .aspectFit,
                                                  options: options) { image, _ in
                continuation.resume(returning: image)
            }
        }
    }
    
    static func requestHighResImage(for asset: PHAsset) async -> UIImage? {
        await withCheckedContinuation { continuation in
            let manager = PHCachingImageManager()
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isSynchronous = false

            let targetSize = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)

            manager.requestImage(for: asset,
                                 targetSize: targetSize,
                                 contentMode: .default,
                                 options: options) { image, _ in
                continuation.resume(returning: image)
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
