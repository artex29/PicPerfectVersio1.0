//
//  OnboardingView.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 10/24/25.
//

enum OnboardingSteps: Int, CaseIterable {
    case welcome
    case intelligentDetection
    case keedOrDeleteInstructions
    case startAndPermissions
}
    

import SwiftUI
struct OnboardingView: View {
    
    @Environment(ContentModel.self) var model
    
    @State private var currentStep: OnboardingSteps = .welcome
    @State private var rotationAngle: Double = 0.0
    @State private var offsetAmount: CGSize = .zero
    @State private var photoAccessButtonPresent: Bool = true
    @State private var notificationButtonPresent: Bool = false
    
    var body: some View {
        
        ZStack {
            AnimatedMesh()
            
            switch currentStep {
            case .welcome:
                WelcomeView()
                    .rotationEffect(Angle(degrees: rotationAngle), anchor: .bottomTrailing)
                    .offset(offsetAmount)
            case .intelligentDetection:
                IntelligentDetectionView()
                    .rotationEffect(Angle(degrees: rotationAngle))
                    .offset(offsetAmount)
            case .keedOrDeleteInstructions:
                KeepOrDeleteInstructions()
                    .rotationEffect(Angle(degrees: rotationAngle))
                    .offset(offsetAmount)
            case .startAndPermissions:
                PermissionsView(photoAccessButtonPresent: $photoAccessButtonPresent, notificationButtonPresent: $notificationButtonPresent)
                    .rotationEffect(Angle(degrees: rotationAngle))
                    .offset(offsetAmount)
            }
            
            if showNextButton() {
                
                VStack {
                    Spacer()
                    
                    Button(nextButtonText()) {
                        // Action for Next button
                        if currentStep != .startAndPermissions {
                            nextStep()
                        }
                        else {
                            model.onboardingPresent = false
                        }
                    }
                    .ifAvailableGlassButtonStyle()
                    .padding(.bottom)
                }
                
            }
        }
        .minMacFrame(width: 500, height: 700)
    }
    
    private func nextButtonText() -> String {
        if currentStep == .startAndPermissions {
            return "Get Started"
        } else {
            return "Next"
        }
    }
    
    private func showNextButton() -> Bool {
        // Logic to hide the Next button
        if currentStep == .startAndPermissions && (photoAccessButtonPresent || notificationButtonPresent) {
            return false
        }
        
        return true
    }
    
    private func nextStep() {
        if let next = OnboardingSteps(rawValue: currentStep.rawValue + 1) {
            withAnimation(.linear(duration: 0.5)) {
                rotationAngle = currentStep != .keedOrDeleteInstructions ? 45 : -45
                let width = currentStep != .keedOrDeleteInstructions ? 300 : -300
                offsetAmount = CGSize(width: width, height: 500)
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                currentStep = next
                rotationAngle = 0.0
                offsetAmount = .zero
            }
            
        } else {
            // Onboarding completed, handle accordingly
        }
    }
    
}

#Preview {
    OnboardingView()
        .environment(ContentModel())
}
