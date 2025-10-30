//
//  RootView.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 10/6/25.
//

import SwiftUI
import StoreKit

struct RootView: View {
    
    @Environment(ContentModel.self) var model
    @Environment(\.scenePhase) var scenePhase
    
    private var manager = PhotoGroupManager()
    
    @State private var feedbackSent: Bool = false
    
    var body: some View {
        
        ZStack {
            HomeView()
                .sheet(isPresented: .constant(model.showHistoryView)) {
                    model.showHistoryView = false
                    if model.activateAppReview {
                        model.requestAppReviewPresent = true
                        model.activateAppReview = false
                    }
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
        .alert("Are you liking PicPerfect", isPresented: .constant(model.requestAppReviewPresent), actions: {
            Button("No it needs impovements") {
                model.requestAppReviewPresent = false
                model.feedbackFormPresent = true
            }
            
            Button("Yes I love it 💛") {
                model.requestAppReviewPresent = false
                showAppStoreReviewAlert()
            }
        })
        .alert("Thank you for your feedback", isPresented: $feedbackSent, actions: {
            Button("You're welcome") {
                feedbackSent = false
            }
        })
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
        .sheet(isPresented: .constant(model.feedbackFormPresent)) {
            model.feedbackFormPresent = false
        } content: {
            FeedbackFormView(messageSent: $feedbackSent)
        }



        
    }
    
    private func activateOnboarding() {
        if ContentModel.useCounter <= 1 {
            model.onboardingPresent = true
        }
    }
    
    private func showAppStoreReviewAlert() {
#if os(macOS)
        SKStoreReviewController.requestReview()
        
#else
        guard let scene = UIApplication.shared.connectedScenes.first(where: {$0.activationState == .foregroundActive}) as? UIWindowScene else {return}
        
        SKStoreReviewController.requestReview(in: scene)
#endif
    }
}

#Preview {
    RootView()
        .environment(ContentModel())
        .environment(PhotoGroupManager())
}
