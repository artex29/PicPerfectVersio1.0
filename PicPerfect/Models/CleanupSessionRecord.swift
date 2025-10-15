//
//  CleanupSessionRecord.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 10/14/25.
//

import Foundation

struct CleanupSessionRecord: Codable, Identifiable {
    let id: UUID 
    let date: Date
    let totalAnalyzed: Int
    let totalDeleted: Int
    let totalKept: Int
    let totalCorrected: Int
    let totalSpaceFreedMB: Double
    let breakdown: [PhotoGroupCategory: Int]
}
