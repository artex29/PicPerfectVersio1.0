//
//  MenuView.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 10/15/25.
//

import SwiftUI

struct MenuView: View {
    
    @Environment(ContentModel.self) var model
    
    var body: some View {
        
        Menu {
            
            Group {
                
                Button("Cleanup Stats", systemImage: "chart.bar.xaxis") {
                    model.showHistoryView = true
                }
                .ifAvailableGlassButtonStyle()
                
                Button("Get PicPerfect+", systemImage: "sparkles") {
                    
                }
                .ifAvailableGlassButtonStyle()
                
                Button("Rate the App", systemImage: "star.bubble.fill") {
                    
                }
                .ifAvailableGlassButtonStyle()
                
                Button("Preferences", systemImage: "slider.horizontal.3") {
                    
                }
                .ifAvailableGlassButtonStyle()
              
                
            }
            .ifAvailableGlassContainer()
            
            
            
        } label: {
            ZStack {
                
                Image(systemName: "rectangle.portrait")
                    .resizable()
                    .scaledToFit()
                    .padding(.trailing, 10)
                    .frame(height: 25)
                
                Image(systemName: "photo")
                    .background()
            }
        }
        .ifAvailableGlassButtonStyle()
        

    }
}

#Preview {
    MenuView()
        .environment(ContentModel())
}
