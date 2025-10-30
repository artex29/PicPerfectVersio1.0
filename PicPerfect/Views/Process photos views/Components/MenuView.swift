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
                
                Button("Cleanup History", systemImage: "chart.bar.xaxis") {
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
                
                Button("Rate the App", systemImage: "star.bubble.fill") {
                    model.requestAppReviewPresent = true
                    Analytics.logEvent("tap_rate_app", parameters: nil)
                }
                .ifAvailableGlassButtonStyle()
                
                Button("Contact us", systemImage: "slider.horizontal.3") {
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
        

    }
}

#Preview {
    MenuView()
        .environment(ContentModel())
}
