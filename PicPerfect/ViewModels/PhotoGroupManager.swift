//
//  PhotoGroupManager.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 10/8/25.
//

import SwiftUI

@MainActor
@Observable
final class PhotoGroupManager {
    var allGroups: [[PhotoGroup]]
    var photosToDelete: Set<ImageInfo> = []
    var photosToKeep: Set<ImageInfo> = []
    var decisionHistory:[DecisionRecord] = []
    
    init(groups: [[PhotoGroup]] = []) {
        self.allGroups = groups
    }
    
    //Removes a photo (by id) from all groups whre it appears
    func processPhoto(withId id: String, action: DecisionActions, for category: PhotoGroupCategory? = nil) {
        // Find the image before modifying anything
        guard let image = allGroups.flatMap({ $0 }).flatMap({ $0.images }).first(where: { $0.id == id }) else {
            print("⚠️ Image not found in any group: \(id)")
            return
        }

        switch action {
        case .delete:
            // 1️⃣ Record all appearances before removing
            makeAllGroupRecords(for: image, action: .delete)
            
            // 2️⃣ Remove from all groups
            for (index, groupArray) in allGroups.enumerated() {
                let updatedGroups = groupArray.map { group -> PhotoGroup in
                    var mutableGroup = group
                    mutableGroup.images.removeAll(where: { $0.id == id })
                    return mutableGroup
                }
                allGroups[index] = updatedGroups.filter { !$0.images.isEmpty }
            }
            
            // 3️⃣ Update tracking sets
            photosToDelete.insert(image)
            photosToKeep.remove(image)
            
        case .keep:
            // 1️⃣ Record all appearances before removal
            makeAllGroupRecords(for: image, action: .keep)
            
            // 2️⃣ Update tracking sets
            photosToKeep.insert(image)
            photosToDelete.remove(image)
            
            // 3️⃣ Remove from UI (optional)
            for (index, groupArray) in allGroups.enumerated() {
                let updatedGroups = groupArray.map { group -> PhotoGroup in
                    var mutableGroup = group
                    mutableGroup.images.removeAll(where: { $0.id == id })
                    return mutableGroup
                }
                allGroups[index] = updatedGroups.filter { !$0.images.isEmpty }
            }
            
        case .undo:
            withAnimation {
                undo(for: category ?? .duplicates)
            }
        }
    }
    
    /// Updates a specific photo if edited or rotated, etc.
    func updatePhoto(_ updatedImage: ImageInfo) {
        for (i, groupArray) in allGroups.enumerated() {
            
            let newGroups = groupArray.map { group in
                var mutableGroup = group
                if let idx = mutableGroup.images.firstIndex(where: { $0.id == updatedImage.id }) {
                    mutableGroup.images[idx] = updatedImage
                }
                return mutableGroup
            }
            allGroups[i] = newGroups
        }
    }
    
    /// Restores the last deleted or modified photo(s) to their original groups and indices.
    /// Restores the last acted-upon image for a specific category,
    /// reinserting it into all categories where it originally appeared.
    private func undo(for category: PhotoGroupCategory) {
        guard let lastRecord = decisionHistory.last(where: { $0.category == category }) else { return }
            let targetImageId = lastRecord.image.id

            // records de esa misma imagen (en todas las categorías)
            let recordsToUndo = decisionHistory.filter { $0.image.id == targetImageId }

            // usamos la versión de la imagen de la categoría actual como referencia
            let referenceImage = lastRecord.image

            // limpiamos historial de esos records
            decisionHistory.removeAll { $0.image.id == targetImageId }

            // restauramos en cada sub-grupo exacto
            for record in recordsToUndo {
                restoreImage(referenceImage, using: record)
            }
        
        switch lastRecord.action {
        case .delete:
            photosToDelete.remove(referenceImage)
        case .keep:
            photosToKeep.remove(referenceImage)
        case .undo:
            break
        }
        
    }
        
        
    /// Reinserts the given `referenceImage` into all groups that originally contained it,
    /// using the stored group and image indices.
    private func restoreImage(_ referenceImage: ImageInfo, using record: DecisionRecord) {
        let section = record.originalGroupIndex
        guard allGroups.indices.contains(section) else {
            print("⚠️ Invalid section index \(section)")
            return
        }

        // Encontrar el sub-grupo correcto por ID
        guard let subgroupIdx = allGroups[section].firstIndex(where: { $0.id == record.id}) else {
            print("⚠️ Subgroup \(record.id) not found in section \(section)")
            return
        }

        var group = allGroups[section][subgroupIdx]

        // Evitar duplicados
        guard !group.images.contains(where: { $0.id == referenceImage.id }) else { return }

        let safeIndex = min(record.originalImageIndex, group.images.count)
        group.images.insert(referenceImage, at: safeIndex)
        allGroups[section][subgroupIdx] = group

        print("✅ Restored image \(referenceImage.id) to subgroup \(group.id) at index \(safeIndex)")
    }
    
    
    // MARK: - History Recording
    private func makeRecord(for image: ImageInfo, in group:PhotoGroup, action: DecisionActions) -> DecisionRecord? {
        
        if let originalGroupIndex = allGroups.firstIndex(where: { $0.contains(where: { $0.id == group.id }) }),
           let originalImageIndex = group.images.firstIndex(where: { $0.id == image.id }) {
            let originalGroupIds = group.images.map { $0.id }
            return DecisionRecord(action: action,
                                  image: image,
                                  originalGroupIndex: originalGroupIndex,
                                  originalImageIndex: originalImageIndex,
                                  originalGroupIds: originalGroupIds,
                                  category: group.category)
        }
        return nil
        
    }
    
    private func makeAllGroupRecords(for image: ImageInfo, action: DecisionActions) {
        
        let groupsContainingImage:[PhotoGroup] = allGroups.flatMap { $0 }.filter { $0.images.contains(where: { $0.id == image.id }) }
        print("📝 Recorded \(groupsContainingImage.count) groups for image \(image.id)")
        
        for group in groupsContainingImage {
            if let record = makeRecord(for: image, in: group, action: action) {
                decisionHistory.append(record)
            }
        }
        
    }
    
}
