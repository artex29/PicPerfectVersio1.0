//
//  PhotoGroupManager.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 10/8/25.
//

import SwiftUI
import Photos

@MainActor
@Observable
final class PhotoGroupManager {
    var allGroups: [PhotoGroup]
    var decisionHistory:[DecisionRecord] = []
    var confirmationActions: [ConfirmationAction] = []
    
    init(groups: [PhotoGroup] = []) {
        self.allGroups = groups
    }
    
    //Removes a photo (by id) from all groups whre it appears
    func processPhoto(withId id: String, action: DecisionActions, for category: PhotoGroupCategory) {
        // Find the image before modifying anything
        guard let image = allGroups.compactMap({ $0 }).flatMap({ $0.images }).first(where: { $0.id == id }) else {
            print("⚠️ Image not found in any group: \(id)")
            return
        }
        
        var confirmationAction: ConfirmationAction? = nil

        switch action {
        case .delete:
            // 1️⃣ Record all appearances before removing
            makeAllGroupRecords(for: image, action: .delete)
            
            // 2️⃣ Remove from all groups
            for (index, group) in allGroups.enumerated() {
                
                var mutableGroup = group
                
                mutableGroup.images.removeAll(where: { $0.id == id })
                
                allGroups[index] = mutableGroup
                
            }
            
            allGroups.removeAll(where: { $0.images.isEmpty })
            
        
            
            // 3️⃣ Update tracking sets
            confirmationAction = ConfirmationAction(imageInfo: image, action: .delete, category: category)
            if let action = confirmationAction {
                // Insert at the beginning to maintain order
                confirmationActions.insert(action, at: 0)
            }

            
        case .keep:
            // 1️⃣ Record all appearances before removal
            makeAllGroupRecords(for: image, action: .keep)
            
            // 3️⃣ Remove from UI (optional)
            for (index, group) in allGroups.enumerated() {
                var mutableGroup = group
                
                mutableGroup.images.removeAll(where: { $0.id == id })
                
                allGroups[index] = mutableGroup
               
            }
            
            allGroups.removeAll(where: { $0.images.isEmpty })
            
            confirmationAction = ConfirmationAction(imageInfo: image, action: .keep, category: category)
            if let action = confirmationAction {
                // Insert at the beginning to maintain order
                confirmationActions.insert(action, at: 0)
            }
            
        case .undo:
            withAnimation {
                undo(for: category)
            }
        }
    }
    
    /// Updates a specific photo if edited or rotated, etc.
    func updatePhoto(_ updatedImage: ImageInfo) {
        for (i, group) in allGroups.enumerated() {
            if group.images.contains(where: {$0.id == updatedImage.id}) {
                var mutableGroup = group
                if let imgIndex = mutableGroup.images.firstIndex(where: { $0.id == updatedImage.id }) {
                    mutableGroup.images[imgIndex] = updatedImage
                    allGroups[i] = mutableGroup
                    print("✅ Updated image \(updatedImage.id) in group \(mutableGroup.id)")
                }
            }
            
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
        
        
        if let actionToRemove = confirmationActions.first(where: { $0.imageInfo.id == targetImageId }) {
            confirmationActions.removeAll { $0.imageInfo.id == targetImageId }
        }
    }
        
        
    /// Reinserts the given `referenceImage` into all groups that originally contained it,
    /// using the stored group and image indices.
    private func restoreImage(_ referenceImage: ImageInfo, using record: DecisionRecord) {
        
        let groupIdx = record.originalGroupIndex
        let origainalIds = record.originalGroupIds
        var group = allGroups[groupIdx]
        
        if allGroups.indices.contains(groupIdx) == false {
            print("⚠️ Invalid section index \(groupIdx)")
            //Creating a new group if the original index is out of bounds
            let newGroup = PhotoGroup(images: [], score: 0.0, category: record.category)
            group = newGroup
            
            allGroups.insert(group, at: groupIdx)
        }
        else  {
            let remainingIds = origainalIds.filter({$0 != referenceImage.id})
            if allGroups[groupIdx].images.map({$0.id}) != remainingIds {
                print("⚠️ Group IDs do not match for group at index \(groupIdx). Expected: \(remainingIds), Found: \(allGroups[groupIdx].images.map({$0.id}))")
                let newGroup = PhotoGroup(images: [], score: 0.0, category: record.category)
                group = newGroup
                allGroups.insert(group, at: groupIdx)
            }
        }


        // Evitar duplicados
        guard !group.images.contains(where: { $0.id == referenceImage.id }) else { return }

        let safeIndex = min(record.originalImageIndex, group.images.count)
        group.images.insert(referenceImage, at: safeIndex)
        
        allGroups[groupIdx] = group

        print("✅ Restored image \(referenceImage.id) to subgroup \(group.id) at index \(safeIndex)")
    }
    
    
    // MARK: - History Recording
    private func makeRecord(for image: ImageInfo, in group:PhotoGroup, action: DecisionActions) -> DecisionRecord? {
        
        if let originalGroupIndex = allGroups.firstIndex(where: { $0.id == group.id }),
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
        
        let groupsContainingImage:[PhotoGroup] = allGroups.filter { $0.images.contains(where: { $0.id == image.id }) }
        print("📝 Recorded \(groupsContainingImage.count) groups for image \(image.id)")
        
        for group in groupsContainingImage {
            if let record = makeRecord(for: image, in: group, action: action) {
                decisionHistory.append(record)
            }
        }
        
    }
    
}
