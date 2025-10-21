//
//  RootView.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 10/6/25.
//

import SwiftUI

struct RootView: View {
    
    @Environment(ContentModel.self) var model
    
    var body: some View {
        
        ZStack {
            HomeView()
                .sheet(isPresented: .constant(model.showHistoryView)) {
                    model.showHistoryView = false
                } content: {
                    CleanupHistoryView()
                }
        }
        .minMacFrame(width: 1200, height: 800)
           

    }
}

#Preview {
    RootView()
        .environment(ContentModel())
}
