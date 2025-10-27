import SwiftData
import Foundation
import Photos

class PersistenceService {
    static func savePendingGroups(context: ModelContext, from manager: PhotoGroupManager) {
        
        clearAllPendingGroups(context: context)
        
        for group in manager.allGroups where !group.images.isEmpty {
            // Evita duplicados del mismo grupo
            let targetId = group.id
            let existingDescriptor = FetchDescriptor<PersistentPhotoGroup>(
                predicate: #Predicate { $0.id == targetId }
            )
            
            if let existing = try? context.fetch(existingDescriptor), !existing.isEmpty {
                for old in existing { context.delete(old) }
            }
            
            let persistent = PersistentPhotoGroup(
                id: group.id,
                imageIds: group.images.map { $0.id },
                score: group.score,
                category: group.category.rawValue,
                isPending: true
            )
            context.insert(persistent)
            
        }
        do {
            try context.save()
            let count = try? context.fetchCount(FetchDescriptor<PersistentPhotoGroup>())
            print("💾 Objects in store:", count ?? 0)
        } catch {
            print("❌ Error saving pending groups: \(error)")
        }
    }
    
    static func fetchPendingGroups(context: ModelContext) async -> [PhotoGroup] {
        // Fetch all persistent groups then filter by isPending
        let descriptor = FetchDescriptor<PersistentPhotoGroup>()
        let savedGroups = (try? context.fetch(descriptor)) ?? []
        let pendingGroups = savedGroups.filter { $0.isPending }
        guard !pendingGroups.isEmpty else { return [] }
        
        var restoredGroups: [PhotoGroup] = []
        
        for group in pendingGroups {
            var images: [ImageInfo] = []
            for id in group.imageIds {
                let fetch = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil)
                if let asset = fetch.firstObject {
                    if let image = await Service.requestImage(for: asset, size: CGSize(width: 256, height: 256)) {
                        let info = ImageInfo(
                            isIncorrect: false,
                            image: image,
                            asset: asset,
                            summary: nil,
                            imageType: nil,
                            orientation: nil,
                            rotationAngle: nil,
                            confidence: nil,
                            source: nil,
                            fileSizeInMB: asset.fileSizeInMB,
                            exposure: nil,
                            blurScore: nil,
                            faceIssues: nil
                        )
                        images.append(info)
                    }
                }
            }
            let category = PhotoGroupCategory(rawValue: group.category) ?? .duplicates
            let photoGroup = PhotoGroup(images: images, score: group.score, category: category)
            restoredGroups.append(photoGroup)
        }
        
        return restoredGroups
    }
    
    static func clearCompletedCategory(context: ModelContext, category: PhotoGroupCategory) {
        
        let fetchDescriptor = FetchDescriptor<PersistentPhotoGroup>()
        
        if let saved = try? context.fetch(fetchDescriptor) {
            for group in saved where group.category == category.rawValue {
                context.delete(group)
            }
            
            try? context.save()
        }
    }
    
    static func cleanupOldPendingGroups(context: ModelContext, olderThan days: Int = 7) {
        let fetch = FetchDescriptor<PersistentPhotoGroup>()
        if let saved = try? context.fetch(fetch) {
            let cutoff = Date().addingTimeInterval(Double(-days * 24 * 3600))
            for group in saved  where group.dateSaved < cutoff {
                context.delete(group)
            }
            try? context.save()
        }
    }
    
    static func clearAllPendingGroups(context: ModelContext) {
        let fetchDescriptor = FetchDescriptor<PersistentPhotoGroup>()
        
        if let saved = try? context.fetch(fetchDescriptor) {
            for group in saved {
                context.delete(group)
            }
            
            try? context.save()
        }
    }

    
}
