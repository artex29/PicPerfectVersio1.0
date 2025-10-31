//
//  PhotoLibraryScanner.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 9/8/25.
//



import Foundation
import Photos
import Vision
import CloudKit

#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

class PhotoLibraryScanner {
    static let shared = PhotoLibraryScanner()
    
    
    static func analyzeLibraryWithEfficiency(
        assets: [PHAsset],
        limit: Int = 50,
        isUserSubscribed: Bool,
        progress: @MainActor @escaping (AnalysisProgress) -> Void
    ) async -> [PhotoGroup] {
        
        var groups: [PhotoGroup] = []
        
        // Ordenar de más viejas a más nuevas
        let sortedAssets = assets.sorted {
            ($0.creationDate ?? .distantPast) < ($1.creationDate ?? .distantPast)
        }
        
        // 1️⃣ Detect duplicates (usa todos los assets, no depende del cache)
        await MainActor.run { progress(.duplicates) }
        if let duplicates = try? await DuplicateService.detectDuplicates(
            for: false,
            assets: sortedAssets,
            threshold: 0.5,
            limit: 30
        ) {
            groups.append(contentsOf: duplicates)
        }
        
        
        // 2️⃣ Detect similars
        await MainActor.run { progress(.similars) }
        if let similars = try? await DuplicateService.detectDuplicates(
            for: true,
            assets: sortedAssets,
            threshold: 0.8,
            limit: 30
        ) {
            groups.append(contentsOf: similars)
        }
        
        // 3️⃣ Load analyzed records for each module from CloudKit
        let faceRecords = await PhotoAnalysisCloudCache.loadRecords(for: .faces)
        
        var blurryRecords:[PhotoAnalysisRecord] = []
        var exposureRecords:[PhotoAnalysisRecord] = []
        
        if isUserSubscribed {
            blurryRecords = await PhotoAnalysisCloudCache.loadRecords(for: .blurry)
            exposureRecords = await PhotoAnalysisCloudCache.loadRecords(for: .exposure)
        }
        
//        let orientationRecords = await PhotoAnalysisCloudCache.loadRecords(for: .orientation)

        // Convert to simple sets of analyzed IDs for faster lookup
        let blurryAnalyzedIDs = Set(blurryRecords.map { $0.id })
        let exposureAnalyzedIDs = Set(exposureRecords.map { $0.id })
        let faceAnalyzedIDs = Set(faceRecords.map { $0.id })
//        let orientationAnalyzedIDs = Set(orientationRecords.map { $0.id })
        
        let allAnalyzedIDs = blurryAnalyzedIDs
            .union(exposureAnalyzedIDs)
            .union(faceAnalyzedIDs)
//            .union(orientationAnalyzedIDs)
        
        let allNoAnalyzedAssets = sortedAssets.filter { !allAnalyzedIDs.contains($0.localIdentifier) }

        // 4️⃣ Filter assets that have not yet been analyzed for each module
//        let blurryAssets = sortedAssets.filter { !blurryAnalyzedIDs.contains($0.localIdentifier) }
//        let exposureAssets = sortedAssets.filter { !exposureAnalyzedIDs.contains($0.localIdentifier) }
//        let faceAssets = sortedAssets.filter { !faceAnalyzedIDs.contains($0.localIdentifier) }
//        let orientationAssets = sortedAssets.filter { !orientationAnalyzedIDs.contains($0.localIdentifier) }
        
        // 5️⃣ Analizar por módulo independiente (solo los faltantes)
        var blurryIssues: [ImageInfo] = []
        var exposureIssues: [ImageInfo] = []
        var faceIssues: [ImageInfo] = []
//        var orientationIssues: [ImageInfo] = []
        
        //Records to save
        var blurryIdsToRecord:[String] = []
        var exposureIdsToRecord:[String] = []
        var faceIdsToRecord:[String] = []
//        var orientationIdsToRecord:[String] = []
        
        if !allNoAnalyzedAssets.isEmpty {
            for (index, asset) in (allNoAnalyzedAssets.prefix(limit)).enumerated() {
                if let image = await Service.requestImage(for: asset, size: CGSize(width: 512, height: 512)) {
                    
                    // Blurry
                    if index == 0 {
                        await MainActor.run { progress(.blurry) }
                    }
                    
                    if let blurryIssue = await BlurryPhotosService.detectBlurriness(in: image, asset: asset) {
                        blurryIssues.append(blurryIssue)
                    }
                    else {
                        if isUserSubscribed {
                            let identifier = asset.localIdentifier
                            blurryIdsToRecord.append(identifier)
                        }
                    }
                    
                    
                    // Exposure
                    if index == Int(Double(limit) * 0.50) {
                        await MainActor.run { progress(.exposure) }
                    }
                    
                    if let exposureIssue = await ExposureService.detectExposureIssueOnImage(image: image, asset: asset) {
                        exposureIssues.append(exposureIssue)
                    }
                    else {
                        if isUserSubscribed {
                            let identifier = asset.localIdentifier
                            exposureIdsToRecord.append(identifier)
                        }
                    }
                    
                    // Faces
                    if index == Int(Double(limit) * 0.75) {
                        await MainActor.run { progress(.faces) }
                    }
                    
                    if let faceIssue = await FaceQualityService.detectBadFaceOnImage(image, asset: asset) {
                        faceIssues.append(faceIssue)
                    }
                    else {
                        let identifier = asset.localIdentifier
                        faceIdsToRecord.append(identifier)
                    }
                    
                    // Orientation, not present in this version due to performance issues
//                    if index == Int(Double(limit) * 0.75) {
//                        await MainActor.run { progress(.orientation) }
//                    }
//                    
//                    if let orientationIssue = await OrientationService.detectMisalignment(in: image, asset: asset) {
//                        orientationIssues.append(orientationIssue)
//                    }
//                    else {
//                        let identifier = asset.localIdentifier
//                        orientationIdsToRecord.append(identifier)
//                        
//                    }
                }
            }
        }
        
        // 6️⃣ Agrupar resultados
        if !blurryIssues.isEmpty { groups.append(groupImages(blurryIssues, by: .blurry)) }
        if !exposureIssues.isEmpty { groups.append(groupImages(exposureIssues, by: .exposure)) }
        if !faceIssues.isEmpty { groups.append(groupImages(faceIssues, by: .faces)) }
//        if !orientationIssues.isEmpty { groups.append(groupImages(orientationIssues, by: .orientation)) }
      

        // 7️⃣ Screenshots (sin cache)
        await MainActor.run { progress(.screenshots) }
        let screenshots = await ScreenShotService.fetchScreenshotsBatch(limit: 30)
        if !screenshots.isEmpty {groups.append(groupImages(screenshots, by: .screenshots))}

        await MainActor.run { progress(.done) }
        
        Task.detached(priority: .background) {
            // Save analyzed records in background
            let blurryRecords = await PhotoAnalysisCloudCache.createAssetRecords(for: blurryIdsToRecord, and: .blurry)
            let exposureRecords = await PhotoAnalysisCloudCache.createAssetRecords(for: exposureIdsToRecord, and: .exposure)
            let faceRecords = await PhotoAnalysisCloudCache.createAssetRecords(for: faceIdsToRecord, and: .faces)
//            let orientationRecords = await PhotoAnalysisCloudCache.createAssetRecords(for: orientationIdsToRecord, and: .orientation)
            
            do {
                let allRecordsSet:Set<CKRecord> = Set(blurryRecords + exposureRecords + faceRecords)// + orientationRecords)
                print("☁️ Uploading \(allRecordsSet.count) analysis records to iCloud...")
                let allRecords = Array(allRecordsSet)
                let chunks = await allRecords.chunked(into: 100)
                for chunk in chunks {
                    try await PhotoAnalysisCloudCache.markBatchAsAnalyzed(chunk)
                }
            }
            catch {
                print("Error marking batch as analyzed: \(error)")
            }
        }
        
        return groups
    }

    
    private static func groupImages(_ images: [ImageInfo], by category: PhotoGroupCategory) -> PhotoGroup {
        return PhotoGroup(images: images, score: nil, category: category)
    }
    
    func fetchProcessedPhotos(with identifiers: [String], completion: @escaping ([PPImage]) -> Void) {
        var images: [PPImage] = []
        let fetchLimit = 10
        
        // Recupera los assets en el mismo orden de los identifiers
        let assets = identifiers.compactMap { id -> PHAsset? in
            PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil).firstObject
        }
        
        // Configuración del request
        let imageManager = PHImageManager.default()
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = true
        requestOptions.deliveryMode = .highQualityFormat
        requestOptions.resizeMode = .fast
        requestOptions.isNetworkAccessAllowed = true
        
        // Pedimos máximo 10 imágenes
        for asset in assets.prefix(fetchLimit) {
            let targetSize = CGSize(width: 1024, height: 1024) // más liviano y seguro
            imageManager.requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFit,
                options: requestOptions
            ) { image, _ in
                if let image = image {
                    images.append(image)
                }
                else {
                    imageManager.requestImageDataAndOrientation(for: asset, options: requestOptions) { data, _, _, _ in
                        if let data = data, let img = PPImage(data: data) {
                            images.append(img)
                        }
                    }
                }
            }
        }
        
        // Llama el completion en el main thread
        DispatchQueue.main.async {
            completion(images)
        }
    }
}

