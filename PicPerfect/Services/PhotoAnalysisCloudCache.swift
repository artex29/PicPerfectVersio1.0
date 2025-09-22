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
    private static let analyzedPhotoRecordsKey = "analyzedPhotoRecords"
    private static let processedPhotosKey = "processedPhotos"

    // MARK: - Guardar un nuevo análisis
    static func markAsAnalyzed(_ asset: PHAsset, orientation: Int?) {
        var records = loadRecords()
        let record = PhotoAnalysisRecord(
            id: asset.localIdentifier,
            date: Date(),
            orientation: orientation
        )
        records[asset.localIdentifier] = record
        saveRecords(records)
    }
    
    static func retrieveProcessedPhotos() -> [String] {
        guard let data = NSUbiquitousKeyValueStore.default.data(forKey: processedPhotosKey) else {return []}
        
        let decoder = JSONDecoder()
        
        return (try? decoder.decode([String].self, from: data)) ?? []
    }
    
    static func saveProcessedPhotos(_ photoIDs: [String]) {
        let encoder = JSONEncoder()
        
        let existing = retrieveProcessedPhotos()
        let updated = existing + photoIDs
        
        guard let data = try? encoder.encode(updated) else { return }
        NSUbiquitousKeyValueStore.default.set(data, forKey: processedPhotosKey)
        NSUbiquitousKeyValueStore.default.synchronize()
    }
    

    // MARK: - Consultar si ya está analizado
    static func isAnalyzed(_ asset: PHAsset) -> Bool {
        return loadRecords()[asset.localIdentifier] != nil
    }

    // MARK: - Obtener un registro completo
    static func record(for asset: PHAsset) -> PhotoAnalysisRecord? {
        return loadRecords()[asset.localIdentifier]
    }

    // MARK: - Helpers
     static func loadRecords() -> [String: PhotoAnalysisRecord] {
        guard let data = NSUbiquitousKeyValueStore.default.data(forKey: analyzedPhotoRecordsKey) else {
            return [:]
        }
        let decoder = JSONDecoder()
        return (try? decoder.decode([String: PhotoAnalysisRecord].self, from: data)) ?? [:]
    }

    private static func saveRecords(_ records: [String: PhotoAnalysisRecord]) {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(records) else { return }
        NSUbiquitousKeyValueStore.default.set(data, forKey: analyzedPhotoRecordsKey)
        NSUbiquitousKeyValueStore.default.synchronize()
    }
    
    static func clearPhotoAnalysisRecords() {
        let store = NSUbiquitousKeyValueStore.default
        let prefix1 = analyzedPhotoRecordsKey// 👈 prefijo o clave base que uses
        let prefix2 = processedPhotosKey
        for (key, _) in store.dictionaryRepresentation {
            if key.hasPrefix(prefix1) || key.hasPrefix(prefix2) {
                store.removeObject(forKey: key)
                print("🗑️ Deleted record: \(key)")
            }
        }
        store.synchronize()
        print("☁️ Todos los records de análisis de fotos fueron eliminados de iCloud")
    }
}
