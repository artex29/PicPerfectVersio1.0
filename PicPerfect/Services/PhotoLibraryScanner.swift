//
//  PhotoLibraryScanner.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 9/8/25.
//



import Foundation
import Photos
import Vision



class PhotoLibraryScanner {
    static let shared = PhotoLibraryScanner()
    
    
    static func analyzeLibraryWithEfficiency(
        assets: [PHAsset],
        limit: Int = 100,
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
            threshold: 0.2,
            limit: 50
        ) {
            groups.append(contentsOf: duplicates)
        }
        
        
        // 2️⃣ Detect similars
        await MainActor.run { progress(.similars) }
        if let similars = try? await DuplicateService.detectDuplicates(
            for: true,
            assets: sortedAssets,
            threshold: 0.8,
            limit: 50
        ) {
            groups.append(contentsOf: similars)
        }
        
        // 3️⃣ Cargar registros de cada módulo
        let blurryRecords = PhotoAnalysisCloudCache.loadRecords(for: .blurry)
        let exposureRecords = PhotoAnalysisCloudCache.loadRecords(for: .exposure)
        let faceRecords = PhotoAnalysisCloudCache.loadRecords(for: .faces)
        let orientationRecords = PhotoAnalysisCloudCache.loadRecords(for: .orientation)
        
        // 4️⃣ Filtrar los assets que no estén analizados por módulo
        let blurryAssets = sortedAssets.filter { blurryRecords[$0.localIdentifier] == nil }
        let exposureAssets = sortedAssets.filter { exposureRecords[$0.localIdentifier] == nil }
        let faceAssets = sortedAssets.filter { faceRecords[$0.localIdentifier] == nil }
        let orientationAssets = sortedAssets.filter { orientationRecords[$0.localIdentifier] == nil }
        
        // 5️⃣ Analizar por módulo independiente (solo los faltantes)
        var blurryIssues: [ImageInfo] = []
        var exposureIssues: [ImageInfo] = []
        var faceIssues: [ImageInfo] = []
        var orientationIssues: [ImageInfo] = []
        
        // 🔹 Blurry
        await MainActor.run { progress(.blurry) }
        if !blurryAssets.isEmpty {
            for asset in blurryAssets.prefix(limit) {
                if let image = await Service.requestImage(for: asset, size: CGSize(width: 512, height: 512)),
                   let issue = await BlurryPhotosService.detectBlurriness(in: image, asset: asset) {
                    blurryIssues.append(issue)
                }
                else {
                    // Record in cache as analyzed with no issues
                    PhotoAnalysisCloudCache.markAsAnalyzed(asset, module: .blurry)
                    
                }
            }
        }
        
        // 🔹 Exposure
        await MainActor.run { progress(.exposure) }
        if !exposureAssets.isEmpty {
            for asset in exposureAssets.prefix(limit) {
                if let image = await Service.requestImage(for: asset, size: CGSize(width: 256, height: 256)),
                   let issue = await ExposureService.detectExposureIssueOnImage(image: image, asset: asset) {
                    exposureIssues.append(issue)
                }
                else {
                    // Record in cache as analyzed with no issues
                    PhotoAnalysisCloudCache.markAsAnalyzed(asset, module: .exposure)
                    
                }
            }
        }

        // 🔹 Faces
        await MainActor.run { progress(.faces) }
        if !faceAssets.isEmpty {
            for asset in faceAssets.prefix(limit) {
                if let image = await Service.requestImage(for: asset, size: CGSize(width: 512, height: 512)),
                   let issue = await FaceQualityService.detectBadFaceOnImage(image, asset: asset) {
                    faceIssues.append(issue)
                }
                else {
                    // Record in cache as analyzed with no issues
                    PhotoAnalysisCloudCache.markAsAnalyzed(asset, module: .faces)
                    
                }
            }
        }

        // 🔹 Orientation
        await MainActor.run { progress(.orientation) }
        if !orientationAssets.isEmpty {
            for asset in orientationAssets.prefix(limit) {
                if let image = await Service.requestImage(for: asset, size: CGSize(width: 256, height: 256)),
                   let issue = await OrientationService.detectMisalignment(in: image, asset: asset) {
                    orientationIssues.append(issue)
                }
                else {
                    // Record in cache as analyzed with no issues
                    PhotoAnalysisCloudCache.markAsAnalyzed(asset, module: .orientation)
                    
                }
            }
        }
        
        // 6️⃣ Agrupar resultados
        if !blurryIssues.isEmpty { groups.append(groupImages(blurryIssues, by: .blurry)) }
        if !exposureIssues.isEmpty { groups.append(groupImages(exposureIssues, by: .exposure)) }
        if !faceIssues.isEmpty { groups.append(groupImages(faceIssues, by: .faces)) }
        if !orientationIssues.isEmpty { groups.append(groupImages(orientationIssues, by: .orientation)) }
      

        // 7️⃣ Screenshots (sin cache)
        await MainActor.run { progress(.screenshots) }
        let screenshots = await ScreenShotService.fetchScreenshotsBatch(limit: limit)
        if !screenshots.isEmpty {groups.append(groupImages(screenshots, by: .screenshots))}

        await MainActor.run { progress(.done) }
        
        return groups
    }

    
    static func analyzeLibrary(assets: [PHAsset], limit: Int = 100, progress:@MainActor @escaping(AnalysisProgress) -> Void) async -> [PhotoGroup] {
        
        var groups: [PhotoGroup] = []
        
        // 1. Detect Duplicates
       await MainActor.run { progress(.duplicates) }
        if let duplicates = try? await DuplicateService.detectDuplicates(for: false, assets: assets, threshold: 0.2, limit: 50) {
            
            let mapped = duplicates.map { dup in
                PhotoGroup(images: dup.images, score: dup.score, category: .duplicates)
            }
            
            groups.append(contentsOf: mapped)
            
        }
        
        // 2.- Detect Similars
       await MainActor.run { progress(.similars) }
        if let similars = try? await DuplicateService.detectDuplicates(for: true, assets: assets, threshold: 0.8, limit: 50) {
            
            let mapped = similars.map { sim in
                PhotoGroup(images: sim.images, score: sim.score, category: .similars)
            }
            
            groups.append(contentsOf: mapped)
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
    
    private static func groupImages(_ images: [ImageInfo], by category: PhotoGroupCategory) -> PhotoGroup {
        return PhotoGroup(images: images, score: nil, category: category)
    }
    
    func fetchProcessedPhotos(with identifiers: [String], completion: @escaping ([PPImage]) -> Void) {
        // Array donde se guardarán las imágenes recuperadas
        var images: [PPImage] = []
        
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

