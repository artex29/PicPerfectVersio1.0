//
//  CleanupSummaryView.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 10/14/25.
//

import SwiftUI
import Photos

struct CleanupSummaryView: View {
    
    init(initialSession: CleanupSessionRecord? = nil, navigationPath: Binding<[NavigationDestination]> = .constant([])) {
        _session = State(initialValue: initialSession)
        self._navigationPath = navigationPath
    }
    
    @Environment(PhotoGroupManager.self) private var manager
    @Environment(\.dismiss) private var dismiss
    
    @State private var session: CleanupSessionRecord? = nil
    
    @Binding var navigationPath: [NavigationDestination]
    
    var body: some View {
        VStack(spacing: 24) {
            if let session = session {
                Text("🎉 Cleanup Complete!")
                    .font(.largeTitle.bold())
                    .padding(.top)
                
                ScrollView {
                    VStack(spacing: 8) {
                        Text("\(session.totalDeleted) photos deleted")
                            .font(.title2.bold())
                        Text("Freed \(String(format: "%.2f MB", session.totalSpaceFreedMB)) of space")
                            .font(.headline)
                            .foregroundColor(.green)
                    }
                    
                    Divider()
                        .padding(.vertical)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Breakdown by Category")
                            .font(.headline)
                        
                        ForEach(session.breakdown.sorted(by: { $0.key.rawValue < $1.key.rawValue }), id: \.key) { category, count in
                            HStack {
                                Text(category.displayName)
                                Spacer()
                                Text("\(count)")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    Divider()
                    
                    VStack(spacing: 4) {
                        Text("Total analyzed: \(session.totalAnalyzed)")
                            .foregroundColor(.gray)
                        if session.totalCorrected > 0 {
                            Text("Corrected \(session.totalCorrected) photos")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                Spacer()
                
                Button("View History") {
                    // navigation to CleanupHistoryView
                }
                .ifAvailableGlassButtonStyle()
                
                Button("Done") {
                    done()
                }
                .foregroundColor(.gray)
                .ifAvailableGlassButtonStyle()
                .padding(.bottom)
            } else {
                ProgressView("Generating report...")
                    .task { await generateSessionData() }
            }
        }
        .padding()
        .foregroundStyle(.white)
        .background(PicPerfectTheme.Colors.background.ignoresSafeArea())
    }
    
    // MARK: - Generate Session Record
    private func generateSessionData() async {
        // 1️⃣ Separate photos by decision
        let deleted = manager.confirmationActions.filter { $0.action == .delete }.map(\.imageInfo)
        let kept = manager.confirmationActions.filter { $0.action == .keep }.map(\.imageInfo)
        let corrected = manager.confirmationActions.filter { $0.category == .orientation && $0.action == .keep && $0.imageInfo.isIncorrect == false }.map(\.imageInfo)
        
        // 2️⃣ Calculate totals
        let totalAnalyzed = deleted.count + kept.count
        let totalDeleted = deleted.count
        let totalKept = kept.count
        let totalCorrected = corrected.count
        
        // 3️⃣ Calculate real freed space
        let totalSpaceFreedMB: Double = deleted.map({$0.fileSizeInMB ?? 0.0}).reduce(0, {$0 + $1})
        
        // 4️⃣ Breakdown by category
        var breakdown: [PhotoGroupCategory: Int] = [:]
        for action in manager.confirmationActions {
            breakdown[action.category, default: 0] += 1
        }
        
        // 5️⃣ Create and save record
        let record = CleanupSessionRecord(
            id: UUID(),
            date: Date(),
            totalAnalyzed: totalAnalyzed,
            totalDeleted: totalDeleted,
            totalKept: totalKept,
            totalCorrected: totalCorrected,
            totalSpaceFreedMB: totalSpaceFreedMB,
            breakdown: breakdown
        )
        
        CleanupHistoryCloudStore.saveRecord(record)
        
        await MainActor.run {
            session = record
        }
    }
    
    private func done() {
        manager.confirmationActions.removeAll()
        navigationPath.removeAll()
        dismiss()
    }
}


#Preview {
    CleanupSummaryView(
        initialSession: CleanupSessionRecord(
            id: UUID(),
            date: Date(),
            totalAnalyzed: 1500, totalDeleted: 120,
            totalKept: 1380,
            totalCorrected: 45,
            totalSpaceFreedMB: 2048,
            breakdown: [
                .duplicates: 50,
                .blurry: 30,
                .exposure: 20,
                .faces: 10,
                .orientation: 5,
                .screenshots: 3,
                .similars: 2
            ]
        )
    )
    .environment(PhotoGroupManager())
}
