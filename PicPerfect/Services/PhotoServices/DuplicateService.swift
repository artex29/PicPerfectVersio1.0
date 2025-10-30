//
//  DuplicateGroup.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 9/22/25.
//


import Photos
import Vision

#if os(macOS)
import AppKit
#else
import UIKit
#endif



enum DuplicateServiceError: Error {
    case imageRequestFailed
    case featurePrintFailed
}

/// Service para detectar duplicados en la librería de fotos
final class DuplicateService {
    
    /// Genera un feature print (embedding) de Vision para comparar imágenes
    private static func featurePrint(for image: PPImage) throws -> VNFeaturePrintObservation {
        #if os(iOS)
        guard let cgImage = image.cgImage else {
            throw DuplicateServiceError.imageRequestFailed
        }
        #elseif os(macOS)
        let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
        guard let cgImage = cgImage else {
            throw DuplicateServiceError.imageRequestFailed
        }
        #endif
        
        let request = VNGenerateImageFeaturePrintRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])
        guard let obs = request.results?.first as? VNFeaturePrintObservation else {
            throw DuplicateServiceError.featurePrintFailed
        }
        return obs
    }
    
    /// Detecta grupos de duplicados en una colección de PHAsset
    /// Main entry: detects duplicate/similar groups scanning oldest→newest,
       /// skipping assets already analyzed in the corresponding module cache.
       static func detectDuplicates(
           for similars: Bool = false,
           assets: [PHAsset],
           threshold: Float = 0.2,
           limit: Int = 100
       ) async throws -> [PhotoGroup] {

           // 1) Filter by cache (module-aware)
           let module: PhotoGroupCategory = similars ? .similars : .duplicates
           //var candidates: [PHAsset] = []
           
           let records = await PhotoAnalysisCloudCache.loadRecords(for: module)
           
           let mappedRecords = Set(records.map { $0.id })
           
           let mappedAssets = assets.map { $0.localIdentifier }
           
           let candidateIds = mappedAssets.filter({!mappedRecords.contains($0)})//Set(mappedAssets).subtracting(mappedRecords)
           
           guard !candidateIds.isEmpty else { return [] }
           
           let candidatesBatch = candidateIds.prefix(limit)

           // 2) Take oldest chunk up to `limit`
           let batch = Array(assets.filter({candidatesBatch.contains($0.localIdentifier)}))
               

           var groups: [PhotoGroup] = []

           // 4) Vision feature prints for near-duplicates
           var processed = Set<Int>()
           let finalThreshold: Float = similars ? 0.8 : threshold

           var featurePrints: [VNFeaturePrintObservation?] = .init(repeating: nil, count: batch.count)
           var imageInfos: [ImageInfo?] = .init(repeating: nil, count: batch.count)

           
           for (index, asset) in batch.enumerated() {
               if let uiImage = await Service.requestImage(for: asset, size: CGSize(width: 512, height: 512)) {
                   let obs = try featurePrint(for: uiImage)
                   featurePrints[index] = obs
                   imageInfos[index] = ImageInfo(isIncorrect: false, image: uiImage, asset: asset, fileSizeInMB: asset.fileSizeInMB)
               }
           }

           for i in 0..<batch.count {
               guard !processed.contains(i),
                     let basePrint = featurePrints[i],
                     let baseImage = imageInfos[i] else { continue }

               var groupImages: [ImageInfo] = [baseImage]
               var distances: [Float] = []
               processed.insert(i)

               for j in (i+1)..<batch.count {
                   guard !processed.contains(j),
                         let otherPrint = featurePrints[j],
                         let otherImage = imageInfos[j] else { continue }

                   var distance: Float = 1.0
                   try basePrint.computeDistance(&distance, to: otherPrint)

                   if distance < finalThreshold {
                       // Evitar que el mismo asset quede en múltiples grupos dentro de esta pasada
                       let asset1 = batch[i]
                       let asset2 = batch[j]
                       let alreadyGrouped = groups
                           .flatMap { $0.images }
                           .contains { info in
                               let id = info.asset?.localIdentifier
                               return id == asset1.localIdentifier || id == asset2.localIdentifier
                           }
                       if alreadyGrouped { continue }

                       groupImages.append(otherImage)
                       distances.append(distance)
                       processed.insert(j)
                   }
               }

               if groupImages.count > 1 {
                   let avgDistance = distances.isEmpty ? 0.0 : distances.reduce(0,+) / Float(distances.count)
                   groups.append(PhotoGroup(images: groupImages, score: avgDistance, category: module))
               }
           }

           // 5) Add bursts (also oldest→newest and respecting limit)
           if !similars {
               let bursts = await getBursts(limit: limit)
               groups.append(contentsOf: bursts)
               
               // 3) Hash-based exact duplicates (fast path)
               let hashGroups = await detectHashDuplicates(assets: batch)
               groups.append(contentsOf: hashGroups)
           }
           
           if groups.isEmpty {
               let assetIds = batch.map { $0.localIdentifier }
               
               let records = PhotoAnalysisCloudCache.createAssetRecords(for: assetIds, and: module)
               
               try await PhotoAnalysisCloudCache.markBatchAsAnalyzed(records)

           }

           return groups
       }

       // MARK: - Bursts (oldest→newest, cache-aware)
       private static func getBursts(limit: Int, offset: Int = 0) async -> [PhotoGroup] {
           var bursts: [PhotoGroup] = []
           var processedBurstIDs = Set<String>()

           let collections = PHAssetCollection.fetchAssetCollections(with: .smartAlbum,
                                                                    subtype: .smartAlbumBursts,
                                                                    options: nil)
           guard let collection = collections.firstObject else { return [] }

           let fo = PHFetchOptions()
           fo.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)] // oldest first
           let allBursts = PHAsset.fetchAssets(in: collection, options: fo)
           guard allBursts.count > 0 else { return [] }

           let start = offset
           let end = min(offset + limit, allBursts.count)
           guard start < end else { return [] }

           for idx in start..<end {
               let asset = allBursts.object(at: idx)
               guard let burstID = asset.burstIdentifier,
                     !processedBurstIDs.contains(burstID) else { continue }

               // Cache skip: si todas las fotos dentro del burst ya están analizadas como duplicates, podemos omitir
               let burstFo = PHFetchOptions()
               burstFo.predicate = NSPredicate(format: "burstIdentifier == %@", burstID)
               let burstAssets = PHAsset.fetchAssets(in: collection, options: burstFo)

               // Ver si hay al menos 2 NO analizadas para que tenga sentido agrupar
               var unanalysed: [PHAsset] = []
               for i in 0..<burstAssets.count {
                   let a = burstAssets.object(at: i)
                   let analyzed = await PhotoAnalysisCloudCache.isAnalyzed(a, module: .duplicates)
                   if !analyzed {
                       unanalysed.append(a)
                       if unanalysed.count >= 2 { break }
                   }
               }
               
               if unanalysed.count < 2 {
                   processedBurstIDs.insert(burstID)
                   continue
               }

               var groupImages: [ImageInfo] = []

               for i in 0..<burstAssets.count {
                   let a = burstAssets.object(at: i)
                   if let image = await Service.requestImage(for: a, size: CGSize(width: 256, height: 256)) {
                       groupImages.append(ImageInfo(isIncorrect: false, image: image, asset: a, fileSizeInMB: a.fileSizeInMB))
                      
                   }
               }
               
               let photoGroup = PhotoGroup(images: groupImages, score: 0.0, category: .duplicates)
               bursts.append(photoGroup)
               
               processedBurstIDs.insert(burstID)
           }

           return bursts
       }

       /// Exact duplicates via perceptual hash, oldest→newest, cache-aware (batch already filtered/sorted)
       private static func detectHashDuplicates(assets: [PHAsset]) async -> [PhotoGroup] {
           var groups: [PhotoGroup] = []
           var buckets: [String: [ImageInfo]] = [:]

           for asset in assets {
               if let uiImage = await Service.requestImage(for: asset, size: CGSize(width: 256, height: 256)),
                  let hash = perceptualHash(for: uiImage) {
                   let info = ImageInfo(isIncorrect: false, image: uiImage, asset: asset, fileSizeInMB: asset.fileSizeInMB)
                   buckets[hash, default: []].append(info)
               }
           }

           for (_, infos) in buckets where infos.count > 1 {
               groups.append(PhotoGroup(images: infos, score: 0.0, category: .duplicates))
           }

           return groups
       }
    
    
    private static func perceptualHash(for image: PPImage, size: CGSize = CGSize(width: 8, height: 8)) -> String? {
        
        #if os(iOS)
        guard let cgImage = image.cgImage else { return nil }
        #elseif os(macOS)
        let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
        guard let cgImage = cgImage else { return nil }
        #endif
        
        // Redimensionar
        #if os(iOS)
        UIGraphicsBeginImageContext(size)
        UIImage(cgImage: cgImage).draw(in: CGRect(origin: .zero, size: size))
        let resized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        #elseif os(macOS)
        let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
        let resized = nsImage.resized( maxDimension: size.width)
        #endif
        
        #if os(iOS)
        guard let smallImage = resized,
              let pixels = smallImage.cgImage?.dataProvider?.data else { return nil }
        #elseif os(macOS)
         let smallImage = resized
        guard let pixels = smallImage.cgImage(forProposedRect: nil, context: nil, hints: nil)?
                .dataProvider?.data else { return nil }
        #endif
        
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

