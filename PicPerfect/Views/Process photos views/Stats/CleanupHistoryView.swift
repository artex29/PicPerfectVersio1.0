//
//  CleanupHistoryView.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 10/14/25.
//
import SwiftUI
import FirebaseAnalytics

struct CleanupHistoryView: View {
    
    @Environment(ContentModel.self) var model
    
    @State private var records: [CleanupSessionRecord] = CleanupHistoryCloudStore.loadRecords()
    
    var totalSpaceFreed: Double {
        records.map(\.totalSpaceFreedMB).reduce(0, +)
    }
    
    let device = DeviceHelper.type
    
    let language = LanguageHelper.language()
    
    var body: some View {
        ZStack {
            
            PicPerfectTheme.Colors.background.ignoresSafeArea()
            
            VStack {
                
                if device == .mac {
                    DismissButton {
                        model.showHistoryView = false
                    }
               }
                    
                
                Text("🧾 Cleanup History")
                    .font(.largeTitle.bold())
                    
                   
                
                Text("Total space saved: \(String(format: "%.2f MB", totalSpaceFreed))")
                    .foregroundColor(.green)
                    .padding(.bottom, 10)
                
                ScrollView {
                    ForEach(records.sorted(by: { $0.date > $1.date })) { record in
                        VStack(alignment: .leading) {
                            
                            Text(record.date.formatted(date: .abbreviated, time: .shortened))
                                .font(.headline)
                            
                            let deleted = language == .english ? "Deleted" : "Eliminados"
                            let saved = language == .english ? "Saved" : "Ahorrados"
                            
                            Text("\(deleted) \(record.totalDeleted) • \(saved) \(String(format: "%.2f MB", record.totalSpaceFreedMB))")
                               
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .applyGlassIfAvailable()
                    }
                    
                    
                }
              
                
                Spacer()
            }
            .foregroundStyle(.white)
            .padding()
          
        }
        .analyticsScreen(name: "CleanupHistoryView", class: "clean_upc_history_view", extraParameters: [
            "total_space_freed_mb": totalSpaceFreed,
            "record_count": records.count
        ])
        
        
    }
}


#Preview {
    CleanupHistoryView()
        .environment(ContentModel())
}
