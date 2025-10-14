//
//  PhotoAnalysisCloudCache.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 9/15/25.
//


import Foundation
import Photos

struct PhotoAnalysisRecord: Codable {
    let id: String            // PHAsset.localIdentifier
    let date: Date            // fecha del análisis
    let orientation: Int?     // ejemplo: resultado numérico de orientación
}

struct PhotoAnalysisCloudCache {
    
    private static let processedPhotosKey = "processedPhotos"

       // MARK: - Save record for a given module
       static func markAsAnalyzed(_ asset: PHAsset,
                                  orientation: Int? = nil,
                                  module: PhotoGroupCategory) {
           var records = loadRecords(for: module)
           let record = PhotoAnalysisRecord(id: asset.localIdentifier,
                                            date: Date(),
                                            orientation: orientation)
           records[asset.localIdentifier] = record
           saveRecords(records, for: module)
       }

       // MARK: - Check if analyzed
       static func isAnalyzed(_ asset: PHAsset, module: PhotoGroupCategory) -> Bool {
           return loadRecords(for: module)[asset.localIdentifier] != nil
       }

       // MARK: - Retrieve record
       static func record(for asset: PHAsset, module: PhotoGroupCategory) -> PhotoAnalysisRecord? {
           return loadRecords(for: module)[asset.localIdentifier]
       }

       // MARK: - Load/Save helpers
     static func loadRecords(for module: PhotoGroupCategory) -> [String: PhotoAnalysisRecord] {
         guard let data = NSUbiquitousKeyValueStore.default.data(forKey: module.photoAnalysisKey) else {
               return [:]
           }
           let decoder = JSONDecoder()
           return (try? decoder.decode([String: PhotoAnalysisRecord].self, from: data)) ?? [:]
       }

       private static func saveRecords(_ records: [String: PhotoAnalysisRecord],
                                       for module: PhotoGroupCategory) {
           let encoder = JSONEncoder()
           guard let data = try? encoder.encode(records) else { return }
           NSUbiquitousKeyValueStore.default.set(data, forKey: module.photoAnalysisKey)
           NSUbiquitousKeyValueStore.default.synchronize()
       }

       // MARK: - Processed photos (shared)
       static func retrieveProcessedPhotos() -> [String] {
           guard let data = NSUbiquitousKeyValueStore.default.data(forKey: processedPhotosKey) else { return [] }
           let decoder = JSONDecoder()
           return (try? decoder.decode([String].self, from: data)) ?? []
       }

       static func saveProcessedPhotos(_ photoIDs: [String]) {
           let encoder = JSONEncoder()
           let existing = retrieveProcessedPhotos()
           let updated = Array(Set(existing + photoIDs)) // avoid duplicates
           guard let data = try? encoder.encode(updated) else { return }
           NSUbiquitousKeyValueStore.default.set(data, forKey: processedPhotosKey)
           NSUbiquitousKeyValueStore.default.synchronize()
       }

       // MARK: - Clear
       static func clearRecords(for module: PhotoGroupCategory) {
           let store = NSUbiquitousKeyValueStore.default
           store.removeObject(forKey: module.photoAnalysisKey)
           store.synchronize()
           print("🧹 Cleared module \(module.rawValue)")
       }

       static func clearAllRecords() {
           let store = NSUbiquitousKeyValueStore.default
           for module in PhotoGroupCategory.allCases {
               store.removeObject(forKey: module.photoAnalysisKey)
           }
           store.removeObject(forKey: processedPhotosKey)
           store.synchronize()
           print("🧹 All analysis records cleared from iCloud")
       }
}
