//
//  HomeView.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 10/6/25.
//

import SwiftUI

enum AppPhase {
    case scan
    case categories
}

struct HomeView: View {
    
    private var manager = PhotoGroupManager(groups: [])
    
   
    @State private var groups:[[PhotoGroup]] = []
    @State private var phase: AppPhase = .scan
    
    var body: some View {
        
        switch phase {
        case .scan:
            
            ScanLibraryView(onFinished: {groups in
                phase = .categories
                manager.allGroups = groups
            })
            
            
        case .categories:
            CategorySplitView(onClose: {
                phase = .scan
            })
            .environment(manager)
        }
       
        
    }
}

#Preview {
    HomeView()
        .environment(ContentModel())
}
