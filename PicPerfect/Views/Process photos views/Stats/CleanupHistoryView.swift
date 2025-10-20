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
    
    let device = DeviceHelper.type
    
    var body: some View {
        ZStack {
            
            PicPerfectTheme.Colors.background.ignoresSafeArea()
            
            VStack {
                
                if device == .mac {
                    DismissButton()
               }
                    
                
                Text("🧾 Cleanup History")
                    .font(.largeTitle.bold())
                    
                   
                
                Text("Total space saved: \(String(format: "%.2f GB", totalSpaceFreed / 1024))")
                    .foregroundColor(.green)
                    .padding(.bottom, 10)
                
                ScrollView {
                    ForEach(records.sorted(by: { $0.date > $1.date })) { record in
                        VStack(alignment: .leading) {
                            
                            Text(record.date.formatted(date: .abbreviated, time: .shortened))
                                .font(.headline)
                            
                            Text("Deleted \(record.totalDeleted) • Saved \(String(format: "%.2f MB", record.totalSpaceFreedMB))")
                               
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
        
    }
}


#Preview {
    CleanupHistoryView()
}
