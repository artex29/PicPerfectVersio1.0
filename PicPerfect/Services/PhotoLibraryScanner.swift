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



class PhotoLibraryScanner {
    static let shared = PhotoLibraryScanner()
    
    
    static func analyzeLibraryWithEfficiency(assets: [PHAsset], limit: Int = 100, progress: @MainActor @escaping(AnalysisProgress) -> Void) async -> [[PhotoGroup]] {
        var groups: [[PhotoGroup]] = []
        
        //Detect duplicates
        await MainActor.run { progress(.duplicates) }
        if let duplicates = try? await DuplicateService.detectDuplicates(for: false, assets: assets, threshold: 0.2, limit: 50) {
            
            let mapped = duplicates.map { dup in
                PhotoGroup(images: dup.images, score: dup.score, category: .duplicates)
            }
            
            groups.append(mapped)
            
        }

        // 2.- Detect Similars
       await MainActor.run { progress(.similars) }
        if let similars = try? await DuplicateService.detectDuplicates(for: true, assets: assets, threshold: 0.5, limit: 50) {
            
            let mapped = similars.map { sim in
                PhotoGroup(images: sim.images, score: sim.score, category: .similars)
            }
            
            groups.append(mapped)
        }
        
        
        var faceIssues: [ImageInfo] = []
        var exposureIssues: [ImageInfo] = []
        var blurryIssues: [ImageInfo] = []
        var orientationIssues: [ImageInfo] = []
        let records = PhotoAnalysisCloudCache.loadRecords()
        
        for index in 0..<min(limit, assets.count) {
            let asset = assets[index]
            
            if let image = await Service.requestImage(for: asset, size: CGSize(width: 256, height: 256)) {
                // Chaeck face quality
                if index == 0 {
                    await MainActor.run { progress(.faces) }
                }
                
                if let faceIssue = await FaceQualityService.detectBadFaceOnImage(image, asset: asset) {
                    faceIssues.append(faceIssue)
                }
                
                // Check exposure issues
                if index == Int(assets.count / 5) {
                    await MainActor.run { progress(.exposure) }
                }
                
                if let exposureIssue = await ExposureService.detectExposureIssueOnImage(image: image, asset: asset) {
                    exposureIssues.append(exposureIssue)
                }
                
                // Check Blurriness
                if index == Int(assets.count * 3 / 5) {
                    await MainActor.run { progress(.blurry) }
                }
                    
                if let blurryIssue = await BlurryPhotosService.detectBlurriness(in: image, asset: asset) {
                    blurryIssues.append(blurryIssue)
                }
                //Check orientation issues
                if index == Int(assets.count * 4 / 5) {
                    await MainActor.run { progress(.orientation) }
                }
                    
                if let orientationIssue = await OrientationService.detectMisalignment(in: image, asset: asset, records: records) {
                    orientationIssues.append(orientationIssue)
                }
            }
            
        }
        
        if !faceIssues.isEmpty {
           
            groups.append(groupImages(faceIssues, by: .faces))
        }
        
        if !exposureIssues.isEmpty {
           
            groups.append(groupImages(exposureIssues, by: .exposure))
        }
        
        if !blurryIssues.isEmpty {
          
            groups.append(groupImages(blurryIssues, by: .blurry))
        }
        
        if !orientationIssues.isEmpty {
           
            groups.append(groupImages(orientationIssues, by: .orientation))
        }
        
        // Get Screenshots
         await MainActor.run { progress(.screenshots) }
        let screenShots = await ScreenShotService.fetchScreenshotsBatch(limit: limit)
        if !screenShots.isEmpty {
            groups.append(groupImages(screenShots, by: .screenshots))
        }
        
        await MainActor.run { progress(.done) }
        
        return groups
    }

    
    static func analyzeLibrary(assets: [PHAsset], limit: Int = 100, progress:@MainActor @escaping(AnalysisProgress) -> Void) async -> [[PhotoGroup]] {
        
        var groups: [[PhotoGroup]] = []
        
        // 1. Detect Duplicates
       await MainActor.run { progress(.duplicates) }
        if let duplicates = try? await DuplicateService.detectDuplicates(for: false, assets: assets, threshold: 0.2, limit: 50) {
            
            let mapped = duplicates.map { dup in
                PhotoGroup(images: dup.images, score: dup.score, category: .duplicates)
            }
            
            groups.append(mapped)
            
        }
        
        // 2.- Detect Similars
       await MainActor.run { progress(.similars) }
        if let similars = try? await DuplicateService.detectDuplicates(for: true, assets: assets, threshold: 0.5, limit: 50) {
            
            let mapped = similars.map { sim in
                PhotoGroup(images: sim.images, score: sim.score, category: .similars)
            }
            
            groups.append(mapped)
        }
        
        // 3.- Detect Blurry
        await MainActor.run { progress(.blurry) }
        let blurry = await BlurryPhotosService.detectBlurryPhotos(assets: assets, limit: limit)
        groups.append(groupImages(blurry, by: .blurry))

        // 4.- Detect Exposure Issues
        await MainActor.run { progress(.exposure) }
        let exposureIssues = await ExposureService.detectExposureIssues(assets: assets, limit: limit)
        groups.append(groupImages(exposureIssues, by: .exposure))
        
        // 5.- Detect Faces with Issues
        await MainActor.run { progress(.faces) }
        let faceIssues = await FaceQualityService.detectBadFaces(assets: assets, limit: limit)
        groups.append(groupImages(faceIssues, by: .faces))
        
        // 6.- Detect Orientation Issues
        await MainActor.run { progress(.orientation) }
        let misaligned = await OrientationService.scanForIncorrectlyOrientedPhotos(limit: 5)
        groups.append(groupImages(misaligned, by: .orientation))
        
        await MainActor.run { progress(.done) }
        return groups
    }
    
    private static func groupImages(_ images: [ImageInfo], by category: PhotoGroupCategory) -> [PhotoGroup] {
        return [PhotoGroup(images: images, score: nil, category: category)]
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

