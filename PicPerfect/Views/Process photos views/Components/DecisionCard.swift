//
//  DecisionCard.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 9/29/25.
//

import SwiftUI

struct DecisionCard: View {
    
    var angle: Double
    
    var opacity: Double {
        return abs(angle) / 15.0
    }
    
    var icon: String {
       angle > 0 ? "hand.thumbsup.fill" : "trash.slash.fill"
    }
    
    var backgroundColor: Color {
        return angle > 0 ? .green : (angle < 0 ? .red : .gray)
    }
    
    var body: some View {
        
        ZStack {
            backgroundColor
            
            Group {
                Circle()
                    .stroke(.white.opacity(0.5), lineWidth: 10)
                    .padding()
                Image(systemName: icon)
                    .foregroundStyle(.white)
                    .font(.system(size: 100))
                    .clipped()
            }
            .frame(width: 200, height: 200)
                
            
        }
        .ignoresSafeArea()
        .opacity(opacity)
       
            
    }
}

#Preview {
    DecisionCard(angle: 15.0)
}
