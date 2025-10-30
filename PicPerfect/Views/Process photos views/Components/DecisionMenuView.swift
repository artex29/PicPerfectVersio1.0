//
//  DecisionMenuView.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 9/26/25.
//

import SwiftUI
import FirebaseAnalytics

struct DecisionMenuView: View {
    
    var deleteAction: () -> Void
    var undoAction: () -> Void
    var keepAction: () -> Void
    var decisionHistory: [DecisionRecord]
    @Binding var swipeInstructions: SwipeInstructions?
    
    var body: some View {
        HStack {
            
            
            Button {
                deleteAction()
                Analytics.logEvent("delete_button_tapped", parameters: nil)
            } label: {
                Image(systemName: "trash.slash.fill")
                    .foregroundColor(.red)
            }
            .ifAvailableGlassButtonStyle()
            .disabled(swipeInstructions != nil && swipeInstructions?.nextAction != .delete)
            
            Spacer()

            Button {
                undoAction()
                Analytics.logEvent("undo_button_tapped", parameters: nil)
            } label: {
                Image(systemName: "arrow.uturn.backward")
                    .foregroundStyle(.blue)
            }
            .ifAvailableGlassButtonStyle()
            .disabledView(decisionHistory.isEmpty)
            .disabled(swipeInstructions != nil && swipeInstructions?.nextAction != .undo)
            
            Spacer()
            
            Button {
                keepAction()
                Analytics.logEvent("keep_button_tapped", parameters: nil)
            } label: {
                Image(systemName: "hand.thumbsup.fill")
                    .foregroundStyle(.green)
            }
            .ifAvailableGlassButtonStyle()
            .disabled(swipeInstructions != nil && swipeInstructions?.nextAction != .keep)
            
            
        }
        .padding()
        .padding(.horizontal)
    }
}

#Preview {
    DecisionMenuView(deleteAction: {}, undoAction: {}, keepAction: {}, decisionHistory: [], swipeInstructions: .constant(nil))
}
