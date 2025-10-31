//
//  MenuView.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 10/15/25.
//

import SwiftUI
import FirebaseAnalytics

struct MenuView: View {
    
    @Environment(ContentModel.self) var model
    
    var body: some View {
        
        Menu {
            
            Group {
                
                Button(.cleanupHistory, systemImage: "chart.bar.xaxis") {
                    model.showHistoryView = true
                    Analytics.logEvent("tap_cleanup_history", parameters: nil)
                }
                .ifAvailableGlassButtonStyle()
                
                Button("Get PicPerfect+", systemImage: "sparkles") {
                    model.showPaywall = true
                    Analytics.logEvent("tap_get_picperfect_plus", parameters: nil)
                }
                .ifAvailableGlassButtonStyle()
                .isPresent(!model.isUserSubscribed)
                
                Button(.rateApp, systemImage: "star.bubble.fill") {
                    model.requestAppReviewPresent = true
                    Analytics.logEvent("tap_rate_app", parameters: nil)
                }
                .ifAvailableGlassButtonStyle()
                
                Button(.contactUs, systemImage: "slider.horizontal.3") {
                    model.feedbackFormPresent = true
                    Analytics.logEvent("tap_contact_us", parameters: nil)
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
        #if os(macOS)
        .background(
           RoundedRectangle(cornerRadius: 10)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.2), radius: 5, x: 2, y: 2)
        )
        #endif
        

    }
}

#Preview {
    MenuView()
        .environment(ContentModel())
}
