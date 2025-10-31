//
//  RootView.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 10/6/25.
//

import SwiftUI
import StoreKit
import FirebaseAnalytics

struct RootView: View {
    
    @Environment(ContentModel.self) var model
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.requestReview) var requestReview
    
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
            NotificationsService.clearBadgeCount()
            
            Analytics.logEvent("app_opened", parameters: [
                "use_counter": ContentModel.useCounter,
                "is_subscribed": model.isUserSubscribed
            ])
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
                Analytics.logEvent("did_not_like_pic_perfect", parameters: nil)
            }
            
            Button("Yes I love it 💛") {
                model.requestAppReviewPresent = false
                showAppStoreReviewAlert()
                Analytics.logEvent("like_pic_perfect", parameters: nil)
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
        requestReview()
    }
}

#Preview {
    RootView()
        .environment(ContentModel())
        .environment(PhotoGroupManager())
}
