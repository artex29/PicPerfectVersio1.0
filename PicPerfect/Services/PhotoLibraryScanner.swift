//
//  PhotoLibraryScanner.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 9/8/25.
//

import Foundation
import Photos
import UIKit
import Vision

struct ImageOrientationResult: Hashable {
    var isIncorrect: Bool
    var image: UIImage
    var asset: PHAsset
}

class PhotoLibraryScanner {
    static let shared = PhotoLibraryScanner()

    func scanForIncorrectlyOrientedPhotos(limit: Int) async -> [ImageOrientationResult] {
        var results: [ImageOrientationResult] = []
        
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

        let assets:PHFetchResult<PHAsset> = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        let imageManager = PHCachingImageManager()

        let options = PHImageRequestOptions()
        options.deliveryMode = .fastFormat
        options.resizeMode = .fast
        options.isSynchronous = false
        
        let records = PhotoAnalysisCloudCache.loadRecords()
        
        let noAnalyzedAssets = assets.objects(at: IndexSet(integersIn: 0..<assets.count)).filter { records[$0.localIdentifier] == nil }

        for i in 0..<noAnalyzedAssets.count {
            
            let asset: PHAsset = noAnalyzedAssets[i]
            
            if results.count >= limit { break }

            
            let targetSize = CGSize(width: 1024, height: 1024)

            if let lowResImage = await requestImage(for: asset, size: targetSize, manager: imageManager, options: options) {
                
                let isIncorrect = await OrientationService.isImageIncorrectlyOriented(in: lowResImage)

                if isIncorrect {
                    if let highResImage = await requestHighResImage(for: asset) {
                        
                        let result = ImageOrientationResult(isIncorrect: true, image: highResImage, asset: asset)
                        
                        let orientationValue = Service.exifOrientation(for: highResImage.imageOrientation)
                        
                        PhotoAnalysisCloudCache.markAsAnalyzed(asset, orientation: orientationValue)
                        
                        results.append(result)
                    }
                }
            }
        }

        return results
    }

    private func requestImage(for asset: PHAsset, size: CGSize, manager: PHCachingImageManager, options: PHImageRequestOptions) async -> UIImage? {
        await withCheckedContinuation { continuation in
            manager.requestImage(for: asset,
                                 targetSize: size,
                                 contentMode: .aspectFit,
                                 options: options) { image, _ in
                continuation.resume(returning: image)
            }
        }
    }
    
    func requestHighResImage(for asset: PHAsset) async -> UIImage? {
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
    
    
    func fetchProcessedPhotos(with identifiers: [String], completion: @escaping ([UIImage]) -> Void) {
        // Array donde se guardarán las imágenes recuperadas
        var images: [UIImage] = []
        
        // Obtenemos los assets a partir de los identifiers
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)
        
        // Configuración para la petición de imagen
        let imageManager = PHImageManager.default()
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = false
        requestOptions.deliveryMode = .highQualityFormat
        requestOptions.resizeMode = .fast
        
        let group = DispatchGroup()
        
        assets.enumerateObjects { asset, _, _ in
            group.enter()
            
            let targetSize = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
            
            imageManager.requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFit,
                options: requestOptions
            ) { image, _ in
                if let image = image {
                    images.append(image)
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            completion(images)
        }
    }
}

