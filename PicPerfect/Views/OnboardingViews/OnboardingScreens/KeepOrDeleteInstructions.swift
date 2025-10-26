//
//  KeepOrDeleteInstructions.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 10/24/25.
//

import SwiftUI

struct SwipeInstructions {
    var swipeRightInstructions: String
    var swipeLeftInstructions: String
    var undoInstructions: String
    var finalMessage: String
    var nextAction: DecisionActions? = nil
}

struct KeepOrDeleteInstructions: View {
    
    @State private var handOffset: CGSize = .zero
    @State private var isAnimating = false
    @State private var swipeInstructions: SwipeInstructions? = nil
    @State private var showHand = true
    
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 10) {
                
                Text("Keep or delete with a simple swipe 👈👉")
                    .font(.title)
                    .bold()
                    .shadow(color: .black, radius: 1, x: 2, y: 2)
                
                VStack {
                    Text("Give it a try")
                        .shadow(color: .black, radius: 1, x: 2, y: 2)
                    
                    switch swipeInstructions?.nextAction {
                    case .delete:
                        Text(swipeInstructions?.swipeLeftInstructions ?? "")
                            .shadow(color: .black, radius: 1, x: 2, y: 2)
                            .font(.caption)
                            .animation(.easeInOut, value: swipeInstructions?.nextAction)
                    case .keep:
                        Text(swipeInstructions?.swipeRightInstructions ?? "")
                            .shadow(color: .black, radius: 1, x: 2, y: 2)
                            .font(.caption)
                            .animation(.easeInOut, value: swipeInstructions?.nextAction)
                    case .undo:
                        Text(swipeInstructions?.undoInstructions ?? "")
                            .shadow(color: .black, radius: 1, x: 2, y: 2)
                            .font(.caption)
                            .animation(.easeInOut, value: swipeInstructions?.nextAction)
                    case .none:
                        Text(swipeInstructions?.finalMessage ?? "")
                            .shadow(color: .black, radius: 1, x: 2, y: 2)
                            .font(.caption)
                            .animation(.easeInOut, value: swipeInstructions?.nextAction)
                    }
                }
                
                ZStack {
                    
                    SwipeDecisionView(photoGroups: [], navigationPath: .constant([]), swipeInstructions: $swipeInstructions)
                        .frame(height: geo.size.height * 0.65)
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                        .environment(PhotoGroupManager())
                        .disabled(swipeInstructions?.nextAction == nil)
                        
                    
                    Image(systemName: "hand.point.up.left.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 50)
                        .offset(handOffset)
                        .animation(isAnimating ? .easeInOut(duration: 1.5).repeatForever(autoreverses: false) : .default, value: handOffset)
                    
                }
                
                Spacer()
                
            }
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .padding()
            .ifAvailableGlassContainer()
            .onAppear {
                swipeInstructions = SwipeInstructions(
                    swipeRightInstructions: "Swipe right or tap the 👍 icon to keep a photo.",
                    swipeLeftInstructions: "Swipe left or tap the 🗑️ icon to delete it.",
                    undoInstructions: "Changed your mind? Tap the ⬅️ arrow below to undo.",
                    finalMessage: "Nice! Now you know how to manage your photos with a simple swipe.",
                    nextAction: .keep
                )
                animateHand(geo: geo)
                
            }
            .onChange(of: swipeInstructions?.nextAction) { oldValue, newValue in
               
                animateHand(geo: geo)
                
                if newValue == nil {
                    showHand = false
                }
            }
        }
    }
    
    private func animateHand(geo: GeometryProxy) {
        switch swipeInstructions?.nextAction {
        case .none:
            break
            
        case .delete:
            isAnimating = true
            withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) { 
                handOffset = CGSize(width: -geo.size.width * 0.3, height: 0)
            }
            
        case .keep:
            isAnimating = true
            withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                handOffset = CGSize(width: geo.size.width * 0.3, height: 0)
            }
            
        case .undo:
            // 🔹 Stop ongoing animation and reset position
            isAnimating = false
            withAnimation(.easeOut(duration: 0.5)) {
                handOffset = CGSize(width: geo.size.width * 0.1, height: geo.size.height * 0.3)
            }
        }
    }
}

#Preview {
    KeepOrDeleteInstructions()
       
}
