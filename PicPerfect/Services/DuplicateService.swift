//
//  DuplicateGroup.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 9/22/25.
//


import Photos
import Vision
import UIKit

struct PhotoGroup: Identifiable {
    let id = UUID()
    let images: [ImageInfo]
    let score: Float?    // optional, for duplicates similarity or blur avg
    let category: PhotoGroupCategory // e.g. "Duplicates", "Blurry", "Exposure", "Faces"
}

enum DuplicateServiceError: Error {
    case imageRequestFailed
    case featurePrintFailed
}

/// Service para detectar duplicados en la librería de fotos
final class DuplicateService {
    
    /// Genera un feature print (embedding) de Vision para comparar imágenes
    private static func featurePrint(for image: UIImage) throws -> VNFeaturePrintObservation {
        guard let cgImage = image.cgImage else {
            throw DuplicateServiceError.imageRequestFailed
        }
        let request = VNGenerateImageFeaturePrintRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])
        guard let obs = request.results?.first as? VNFeaturePrintObservation else {
            throw DuplicateServiceError.featurePrintFailed
        }
        return obs
    }
    
    /// Detecta grupos de duplicados en una colección de PHAsset
    static func detectDuplicates(
        for similars: Bool = false,
        assets: [PHAsset],
        threshold: Float = 0.2,
        limit: Int = 100
    ) async throws -> [PhotoGroup] {
        var groups: [PhotoGroup] = []
        
        // 1. Hash duplicates (exactos)
        let hashGroups = await detectHashDuplicates(assets: assets, limit: limit)
        groups.append(contentsOf: hashGroups)
        
        var processed: Set<Int> = []
        let finalThreshold: Float = similars ? 0.5 : threshold
        // Guardar observaciones y sus imágenes
        var featurePrints: [VNFeaturePrintObservation?] = []
        var imageInfos: [ImageInfo?] = []
        
        for (index, asset) in assets.enumerated() {
            guard index < limit else { break }
                
            if let uiImage = await Service.requestImage(for: asset, size: CGSize(width: 256, height: 256)) {
                let obs = try featurePrint(for: uiImage)
                featurePrints.append(obs)
                imageInfos.append(ImageInfo(isIncorrect: false, image: uiImage, asset: asset))
            } else {
                featurePrints.append(nil)
                imageInfos.append(nil)
            }
        }
        
        // Comparar assets entre sí
        for i in 0..<min(limit, assets.count) {
            guard !processed.contains(i),
                  let basePrint = featurePrints[i],
                  let baseImage = imageInfos[i] else { continue }
            
            var groupImages: [ImageInfo] = [baseImage]
            var distances: [Float] = []
            processed.insert(i)
            
            for j in (i+1)..<min(limit, assets.count) {
                guard !processed.contains(j),
                      let otherPrint = featurePrints[j],
                      let otherImage = imageInfos[j] else { continue }
                
                var distance: Float = 1.0
                try basePrint.computeDistance(&distance, to: otherPrint)
                
                if distance < finalThreshold {
                    
                    let asset1 = assets[i]
                    let asset2 = assets[j]
                    
                    guard !groups.map({ $0.images })
                        .flatMap({ $0 })
                        .contains(where: {
                            $0.asset.localIdentifier == asset1.localIdentifier ||
                            $0.asset.localIdentifier == asset2.localIdentifier
                        }) else {
                        
                        continue
                    }
                    
                    groupImages.append(otherImage)
                    distances.append(distance)
                    processed.insert(j)
                }
            }
            
            if groupImages.count > 1 {
                let avgDistance = distances.isEmpty ? 0.0 : distances.reduce(0,+)/Float(distances.count)
                groups.append(PhotoGroup(images: groupImages, score: avgDistance, category: .duplicates) )
            }
        }
        
        // add bursts
        let bursts = similars ? [] : await getBursts(limit: limit)
        groups.append(contentsOf: bursts)
        
        return groups
    }
    
    private static func getBursts(limit: Int, offset: Int = 0) async -> [PhotoGroup] {
        var bursts: [PhotoGroup] = []
        var processedIdentifiers: Set<String> = []
        
        let burstsCollections = PHAssetCollection.fetchAssetCollections(
            with: .smartAlbum,
            subtype: .smartAlbumBursts,
            options: nil
        )
        
        guard let collection = burstsCollections.firstObject else {
            return []
        }
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let allBursts = PHAsset.fetchAssets(in: collection, options: fetchOptions)
        guard allBursts.count > 0 else { return [] }
        
        let start = offset
        let end = min(offset + limit, allBursts.count)
        guard start < end else { return [] }
        
        for index in start..<end {
            let asset = allBursts.object(at: index)
            
            guard let burstID = asset.burstIdentifier,
                  !processedIdentifiers.contains(burstID) else {
                continue
            }
            
            let burstFetchOptions = PHFetchOptions()
            burstFetchOptions.predicate = NSPredicate(format: "burstIdentifier == %@", burstID)
            let burstAssets = PHAsset.fetchAssets(in: collection, options: burstFetchOptions)
            
            var groupImages: [ImageInfo] = []
            
            for i in 0..<burstAssets.count {
                let a = burstAssets.object(at: i)
                
                if let image = await Service.requestImage(for: a, size: CGSize(width: 256, height: 256)) {
                    let info = ImageInfo(isIncorrect: false, image: image, asset: a)
                    groupImages.append(info)
                }
            }
            
            if groupImages.count > 1 {
                bursts.append(PhotoGroup(images: groupImages, score: nil, category: .duplicates))
            }
            
            processedIdentifiers.insert(burstID)
        }
        
        return bursts
    }
    
    /// Detecta duplicados exactos por hash
    private static func detectHashDuplicates(assets: [PHAsset], limit: Int = 100) async -> [PhotoGroup] {
        var groups: [PhotoGroup] = []
        var seen: [String: [ImageInfo]] = [:]
        
        for (index, asset) in assets.enumerated() {
            guard index < limit else { break }
            
            if let uiImage = await Service.requestImage(for: asset, size: CGSize(width: 256, height: 256)) {
                if let hash = perceptualHash(for: uiImage) {
                    let info = ImageInfo(isIncorrect: false, image: uiImage, asset: asset)
                    seen[hash, default: []].append(info)
                }
            }
        }
        
        for (_, infos) in seen {
            if infos.count > 1 {
                groups.append(PhotoGroup(images: infos, score: 0.0, category: .duplicates))
            }
        }
        
        return groups
    }

    private static func perceptualHash(for image: UIImage, size: CGSize = CGSize(width: 8, height: 8)) -> String? {
        guard let cgImage = image.cgImage else { return nil }
        
        // Redimensionar
        UIGraphicsBeginImageContext(size)
        UIImage(cgImage: cgImage).draw(in: CGRect(origin: .zero, size: size))
        let resized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let smallImage = resized,
              let pixels = smallImage.cgImage?.dataProvider?.data else { return nil }
        
        let ptr = CFDataGetBytePtr(pixels)!
        let length = CFDataGetLength(pixels)
        
        // Calcular promedio de luminancia
        var total: Int = 0
        var values: [UInt8] = []
        for i in stride(from: 0, to: length, by: 4) {
            let r = Int(ptr[i])
            let g = Int(ptr[i+1])
            let b = Int(ptr[i+2])
            let gray = UInt8((r + g + b) / 3)
            values.append(gray)
            total += Int(gray)
        }
        let avg = total / values.count
        
        // Crear hash binario
        return values.map { $0 > avg ? "1" : "0" }.joined()
    }
}


