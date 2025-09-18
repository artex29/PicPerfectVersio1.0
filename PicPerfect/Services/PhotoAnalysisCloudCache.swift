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
    private static let key = "analyzedPhotoRecords"

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

    // MARK: - Consultar si ya está analizado
    static func isAnalyzed(_ asset: PHAsset) -> Bool {
        return loadRecords()[asset.localIdentifier] != nil
    }

    // MARK: - Obtener un registro completo
    static func record(for asset: PHAsset) -> PhotoAnalysisRecord? {
        return loadRecords()[asset.localIdentifier]
    }

    // MARK: - Helpers
    private static func loadRecords() -> [String: PhotoAnalysisRecord] {
        guard let data = NSUbiquitousKeyValueStore.default.data(forKey: key) else {
            return [:]
        }
        let decoder = JSONDecoder()
        return (try? decoder.decode([String: PhotoAnalysisRecord].self, from: data)) ?? [:]
    }

    private static func saveRecords(_ records: [String: PhotoAnalysisRecord]) {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(records) else { return }
        NSUbiquitousKeyValueStore.default.set(data, forKey: key)
        NSUbiquitousKeyValueStore.default.synchronize()
    }
    
    static func clearPhotoAnalysisRecords() {
        let store = NSUbiquitousKeyValueStore.default
        let prefix = "analyzedPhotoRecords" // 👈 prefijo o clave base que uses
        for (key, _) in store.dictionaryRepresentation {
            if key.hasPrefix(prefix) {
                store.removeObject(forKey: key)
                print("🗑️ Deleted record: \(key)")
            }
        }
        store.synchronize()
        print("☁️ Todos los records de análisis de fotos fueron eliminados de iCloud")
    }
}
