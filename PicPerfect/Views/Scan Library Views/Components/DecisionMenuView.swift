//
//  DecisionMenuView.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 9/26/25.
//

import SwiftUI

struct DecisionMenuView: View {
    
    var deleteAction: () -> Void
    var undoAction: () -> Void
    var keepAction: () -> Void
    
    var body: some View {
        HStack {
            
            
            Button {
                deleteAction()
            } label: {
                Image(systemName: "trash.slash.fill")
                    .foregroundColor(.red)
            }
            .ifAvailableGlassButtonStyle()
            
            Spacer()

            Button {
                undoAction()
            } label: {
                Image(systemName: "arrow.uturn.backward")
                    .foregroundStyle(.blue)
            }
            .ifAvailableGlassButtonStyle()
            Spacer()
            
            Button {
                keepAction()
            } label: {
                Image(systemName: "hand.thumbsup.fill")
                    .foregroundStyle(.green)
            }
            .ifAvailableGlassButtonStyle()
            
            
        }
        
        .padding()
        .padding(.horizontal)
    }
}

#Preview {
    DecisionMenuView(deleteAction: {}, undoAction: {}, keepAction: {})
}
