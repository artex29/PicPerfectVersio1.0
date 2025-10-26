//
//  HomeView.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 10/6/25.
//

import SwiftUI
import SwiftData

enum AppPhase {
    case scan
    case categories
}

struct HomeView: View {
    
    private var manager = PhotoGroupManager()
    
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var context
    @State private var groups:[[PhotoGroup]] = []
    @State private var phase: AppPhase = .scan
    
    
    
    var body: some View {
        
        ZStack {
            switch phase {
            case .scan:
                
                ZStack(alignment: .top) {
                    ScanLibraryView(onFinished: {groups in
                        phase = .categories
                        manager.allGroups = groups
                    })
                    
                    HStack {
                        Spacer()
                        MenuView()
                    }
                    .padding()
                }
                .environment(manager)
                
            case .categories:
                CategorySplitView(onClose: {
                    phase = .scan
                })
                .environment(manager)
            }
        }
        .task {
//            PhotoAnalysisCloudCache.createTestRecord()
            if manager.allGroups.isEmpty {
                let pendingGroups = await PersistenceService.fetchPendingGroups(context: context)
                
                if !pendingGroups.isEmpty {
                    manager.allGroups = pendingGroups
                    phase = .categories
                }
            }
        }
        .onChange(of: scenePhase) { oldValue, newValue in
//            PersistenceService.clearAllPendingGroups(context: context)
            if manager.allGroups.isEmpty {
                if newValue == .active && phase != .categories {
                    // App moved to foreground
                    Task {
                        let pendingGroups = await PersistenceService.fetchPendingGroups(context: context)
                        
                        if !pendingGroups.isEmpty {
                            manager.allGroups = pendingGroups
                            phase = .categories
                        }
                    }
                }
            }
            else {
                 if newValue == .background || newValue == .inactive {
                    // App moved to background
                    // Save any pending groups to Core Data
                    PersistenceService.savePendingGroups(context: context, from: manager)
                }
            }
        }
       
        
    }
}

#Preview {
    HomeView()
        .environment(ContentModel())
        .environment(PhotoGroupManager())
}
