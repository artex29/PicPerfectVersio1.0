//
//  CleanupHistoryCloudStore.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 10/14/25.
//

import Foundation

final class CleanupHistoryCloudStore {
    private static let historyKey = "cleanupHistoryrecords"
    
    static func saveRecord(_ record: CleanupSessionRecord) {
        var all = loadRecords()
        all.append(record)
        
        let encoder = JSONEncoder()
        
        if let data = try? encoder.encode(all) {
            let store = NSUbiquitousKeyValueStore.default
            store.set(data, forKey: historyKey)
            store.synchronize()
        }
    }
    
    static func loadRecords() -> [CleanupSessionRecord] {
        guard let data = NSUbiquitousKeyValueStore.default.data(forKey: historyKey) else {return []}
        let decoder = JSONDecoder()
        return (try? decoder.decode([CleanupSessionRecord].self, from: data)) ?? []
    }
    
    static func clearAll() {
        let store = NSUbiquitousKeyValueStore.default
        store.removeObject(forKey: historyKey)
        store.synchronize()
        print("🧹 Cleared all cleanup history records from iCloud.")
    }
}

