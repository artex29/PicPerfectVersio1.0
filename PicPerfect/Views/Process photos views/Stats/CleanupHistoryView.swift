//
//  CleanupHistoryView.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 10/14/25.
//
import SwiftUI

struct CleanupHistoryView: View {
    @State private var records: [CleanupSessionRecord] = CleanupHistoryCloudStore.loadRecords()
    
    var totalSpaceFreed: Double {
        records.map(\.totalSpaceFreedMB).reduce(0, +)
    }
    
    var body: some View {
        VStack {
            Text("🧾 Cleanup History")
                .font(.largeTitle.bold())
                .padding(.top)
            
            Text("Total space saved: \(String(format: "%.2f GB", totalSpaceFreed / 1024))")
                .foregroundColor(.green)
                .padding(.bottom, 10)
            
            List(records.sorted(by: { $0.date > $1.date })) { record in
                VStack(alignment: .leading) {
                    Text(record.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.headline)
                    Text("Deleted \(record.totalDeleted) • Saved \(String(format: "%.2f MB", record.totalSpaceFreedMB))")
                        .foregroundColor(.secondary)
                }
            }
            
            
            Spacer()
        }
        .padding()
        .background(Color(PicPerfectTheme.Colors.background).ignoresSafeArea())
    }
}


#Preview {
    CleanupHistoryView()
}
