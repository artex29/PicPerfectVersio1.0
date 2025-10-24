//
//  PhotoAnalysisCloudCache.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 9/15/25.
//


import Foundation
import CloudKit
import Photos

struct PhotoAnalysisRecord: Codable {
    let id: String            // PHAsset.localIdentifier
    let date: Date            // fecha del análisis
    let orientation: Int?     // ejemplo: resultado numérico de orientación
}

enum CloudKitError: Error {
    case recordNotFound
    case unknown(Error)
}

struct PhotoAnalysisCloudCache {
    
    private static let container = CKContainer.default()
    private static let database:CKDatabase = container.privateCloudDatabase
    private static let recordType = "AnalyzedPhotoRecord"
    private static let processedPhotosKey = "processedPhotos"
    
    // MARK: - Save a record for a given module (CloudKit)
    static func createAssetRecords(for assetIds: [String],
                                   and module: PhotoGroupCategory,
                                   with orientation: Int? = nil) -> [CKRecord] {
        var records: [CKRecord] = []
        
        for id in assetIds {
            let record = CKRecord(recordType: recordType)
            record["assetId"] = id as CKRecordValue
            record["module"] = module.rawValue as CKRecordValue
            record["date"] = Date() as CKRecordValue
            if let orientation = orientation {
                record["orientation"] = orientation as CKRecordValue
            }
            
            records.append(record)
        }
        
        return records
    }
    
    static func markBatchAsAnalyzed(_ records: [CKRecord]) async throws {
        let operation = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: nil)
        operation.savePolicy = .changedKeys
        operation.isAtomic = false  // permite guardar parcialmente si algo falla
        
        return await withCheckedContinuation { continuation in
            operation.modifyRecordsResultBlock = { result in
                switch result {
                case .success:
                    print("☁️ Successfully saved \(records.count) records.")
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error as! Never)
                }
            }
            
            PhotoAnalysisCloudCache.database.add(operation)
        }
        
    }
    
    static func markAsAnalyzed(_ asset: PHAsset,
                               orientation: Int? = nil,
                               module: PhotoGroupCategory) async throws {
        
        let record = CKRecord(recordType: recordType)
        record["assetId"] = asset.localIdentifier as CKRecordValue
        record["module"] = module.rawValue as CKRecordValue
        record["date"] = Date() as CKRecordValue
        if let orientation = orientation {
            record["orientation"] = orientation as CKRecordValue
        }
        
        do {
            try await database.save(record)
            print("☁️ Saved record for \(asset) in module \(module.rawValue)")
        } catch {
            throw CloudKitError.unknown(error)
        }
    }
    
    // MARK: - Check if analyzed
    static func isAnalyzed(_ asset: PHAsset, module: PhotoGroupCategory) async -> Bool {
        
        do {
            let predicate = NSPredicate(format: "assetId == %@ AND module == %@", asset.localIdentifier, module.rawValue)
            let query = CKQuery(recordType: recordType, predicate: predicate)
            let result = try await database.records(matching: query, resultsLimit: 1)
            return !result.matchResults.isEmpty
        } catch {
            print("⚠️ CloudKit query failed: \(error)")
            return false
        }
    }
    
    // MARK: - Retrieve records for module
    static func loadRecords(for module: PhotoGroupCategory) async -> [PhotoAnalysisRecord] {
        var records: [PhotoAnalysisRecord] = []
        let predicate = NSPredicate(format: "module == %@", module.rawValue)
        let query = CKQuery(recordType: recordType, predicate: predicate)
        
        var cursor: CKQueryOperation.Cursor? = nil
        
        repeat {
            do {
                // Crear operación de consulta
                let operation: CKQueryOperation
                if let existingCursor = cursor {
                    operation = CKQueryOperation(cursor: existingCursor)
                } else {
                    operation = CKQueryOperation(query: query)
                }
                
                operation.resultsLimit = 400 // puedes ajustar este valor (máximo práctico ≈ 400)
                
                var batch: [PhotoAnalysisRecord] = []
                
                // Callback por cada record recuperado
                operation.recordMatchedBlock = { _, result in
                    switch result {
                    case .success(let ckRecord):
                        if let assetId = ckRecord["assetId"] as? String,
                           let date = ckRecord["date"] as? Date {
                            let orientation = ckRecord["orientation"] as? Int
                            let record = PhotoAnalysisRecord(id: assetId, date: date, orientation: orientation)
                            batch.append(record)
                        }
                    case .failure(let error):
                        print("⚠️ Record match error: \(error.localizedDescription)")
                    }
                }
                
                // Ejecutar la operación y esperar a que termine
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                    operation.queryResultBlock = { result in
                        switch result {
                        case .success(let nextCursor):
                            cursor = nextCursor
                            records.append(contentsOf: batch)
                            continuation.resume()
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                    }
                    
                    database.add(operation)
                }
            } catch {
                print("⚠️ CloudKit query failed for \(module.rawValue): \(error.localizedDescription)")
                cursor = nil
            }
        } while cursor != nil
        
        print("☁️ Loaded \(records.count) records for module \(module.rawValue)")
        return records
    }
    
    // MARK: - Clear CloudKit data
    static func clearRecords(for module: PhotoGroupCategory) async {
        do {
            let predicate = NSPredicate(format: "module == %@", module.rawValue)
            let query = CKQuery(recordType: recordType, predicate: predicate)
            let result = try await database.records(matching: query)
            
            for (_, matchResult) in result.matchResults {
                if let record = try? matchResult.get() {
                    try await database.deleteRecord(withID: record.recordID)
                }
            }
            print("🧹 Cleared CloudKit records for module: \(module.rawValue)")
        } catch {
            print("⚠️ Failed to clear records for \(module.rawValue): \(error)")
        }
    }
    
    static func clearAllRecords() async {
        for module in PhotoGroupCategory.allCases {
            await clearRecords(for: module)
        }
        print("🧹 All CloudKit analysis records cleared")
    }
    
    // ==========================================================
    // MARK: - Processed Photos (NSUbiquitousKeyValueStore)
    // ==========================================================
    
    /// Retrieves identifiers of photos already processed and displayed in the app.
    static func retrieveProcessedPhotos() -> [String] {
        guard let data = NSUbiquitousKeyValueStore.default.data(forKey: processedPhotosKey) else { return [] }
        let decoder = JSONDecoder()
        return (try? decoder.decode([String].self, from: data)) ?? []
    }
    
    /// Saves identifiers of photos already processed.
    static func saveProcessedPhotos(_ photoIDs: [String]) {
        let encoder = JSONEncoder()
        let existing = retrieveProcessedPhotos()
        let updated = Array(Set(existing + photoIDs)) // avoid duplicates
        guard let data = try? encoder.encode(updated) else { return }
        NSUbiquitousKeyValueStore.default.set(data, forKey: processedPhotosKey)
        NSUbiquitousKeyValueStore.default.synchronize()
        print("💾 Saved \(updated.count) processed photo IDs to iCloud KVS")
    }
    
    /// Clears local lightweight processed photo IDs (not CloudKit records)
    static func clearProcessedPhotos() {
        let store = NSUbiquitousKeyValueStore.default
        store.removeObject(forKey: processedPhotosKey)
        store.synchronize()
        print("🧹 Cleared processed photos from NSUbiquitousKeyValueStore")
    }
    
    //Only the first time to create the record type in CloudKit Dashboard
    static func createTestRecord() {
        let container = CKContainer(identifier: "iCloud.net.artexcomputer.PicPerfect")
        let database = container.privateCloudDatabase
        
        let record = CKRecord(recordType: "AnalyzedPhotoRecord")
        record["assetId"] = "test_id" as NSString
        record["date"] = Date() as NSDate
        record["orientation"] = 0 as NSNumber
        record["module"] = "test" as NSString
        
        database.save(record) { saved, error in
            if let error = error {
                print("❌ Failed to save test record:", error)
            } else {
                print("✅ Record type created successfully in CloudKit")
            }
        }
    }
}
