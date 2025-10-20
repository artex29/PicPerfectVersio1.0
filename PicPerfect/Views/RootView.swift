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
        
        HomeView()
            .sheet(isPresented: .constant(model.showHistoryView)) {
                model.showHistoryView = false
            } content: {
                CleanupHistoryView()
            }
           

    }
}

#Preview {
    RootView()
        .environment(ContentModel())
}
