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
                    
                
                HStack {
                    
                    Image(.cleanupHistoryMainIcon)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 40)
                    
                    Text("Cleanup History")
                        .font(.largeTitle.bold())
                }
                    
                   
                ZStack {
                    
                    RoundedRectangle(cornerRadius: 15)
                        .fill(
                            LinearGradient(colors: [
                                PicPerfectTheme.Colors.picDarkViolet.opacity(0.8),
                                PicPerfectTheme.Colors.picLightBlue.opacity(0.8)
                            ], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                
                    
                    VStack {
                        Text("Total Space Saved")
                            .foregroundColor(.white)
                            .padding(.bottom, 10)
                        
                        Text(String(format: "%.2f MB", totalSpaceFreed))
                            .font(.largeTitle)
                            .bold()
                            .foregroundColor(PicPerfectTheme.Colors.picLightBlue)
                    }
                }
                .frame(height: 120)
                
               
                
                ScrollView {
                    ForEach(records.sorted(by: { $0.date > $1.date })) { record in
                        
                        VStack(alignment: .leading) {
                            HStack(alignment: .top) {
                                Image(systemName: "calendar")
                                    .foregroundStyle(PicPerfectTheme.Colors.picLightBlue)
                                
                                let date = record.date
                                
                                VStack(alignment: .leading) {
                                    Text(date.formatted(date: .abbreviated, time: .omitted))
                                        .fontWeight(.semibold)
                                    Text(date.formatted(date: .omitted, time: .shortened))
                                        .opacity(0.7)
                                    
                                }
                                
                                Spacer()
                            }
                            
                            HStack {
                                HStack {
                                    Image(.cleanupHistoryTrashIcon)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 40)
                                        
                                    
                                    VStack(alignment: .leading) {
                                        Text(.photos)
                                            .font(.callout)
                                            .opacity(0.8)
                                        
                                        Text("\(record.totalDeleted)")
                                            .fontWeight(.semibold)
                                        
                                    }
                                }
                                
                                Spacer()
                                
                                HStack {
                                    Image(.cleanupHistorySavedIcon)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 40)
                                        
                                    
                                    VStack(alignment: .leading) {
                                        Text(.saved)
                                            .font(.callout)
                                            .opacity(0.8)
                                        
                                        Text(String(format: "%.2f MB", record.totalSpaceFreedMB))
                                            .fontWeight(.semibold)
                                            .foregroundStyle(.green)
                                        
                                    }
                                }
                            }
                            .padding(.top, 10)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .applyGlassIfAvailable()
                        
                        
                    }
                    
                    
                }
                .padding(.top)
              
                
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
