//
//  RootView.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 10/6/25.
//

import SwiftUI

struct RootView: View {
    
    @Environment(ContentModel.self) var model
    @Environment(\.scenePhase) var scenePhase
    
    private var manager = PhotoGroupManager()
    
    var body: some View {
        
        ZStack {
            HomeView()
                .sheet(isPresented: .constant(model.showHistoryView)) {
                    model.showHistoryView = false
                } content: {
                    CleanupHistoryView()
                }
        }
        .onAppear(perform: {
            activateOnboarding()
        })
        .minMacFrame(width: 1200, height: 800)
        .onChange(of: scenePhase) { oldValue, newValue in
            if newValue == .active {
                ContentModel.useCounter += 1
                print("App launched \(ContentModel.useCounter) times")
            }
        }
        
        .sheet(isPresented: .constant(model.showPaywall)) {
            model.showPaywall = false
            if model.isUserSubscribed {
                ContentModel.nextScanDate = 0.0
            }
        } content: {
            PaywallView()
        }
        .customDeviceSheet(isPresented: .constant(model.onboardingPresent)) {
            model.onboardingPresent = false
        } content: {
            OnboardingView()
        }


        
    }
    
    private func activateOnboarding() {
        if ContentModel.useCounter <= 1 {
            model.onboardingPresent = true
        }
    }
}

#Preview {
    RootView()
        .environment(ContentModel())
        .environment(PhotoGroupManager())
}
