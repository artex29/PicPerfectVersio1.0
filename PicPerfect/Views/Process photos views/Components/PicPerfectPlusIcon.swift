//
//  PicPerfectPlusIcon.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 10/27/25.
//

import SwiftUI

struct PicPerfectPlusIcon: View {
    
    @State private var scale: CGSize = CGSize(width: 1.0, height: 1.0)
    
    var body: some View {
        
        Text("✨")
            .scaleEffect(scale)
            .font(.system(size: 30))
            .onAppear {
                animateSparkle()
            }

    }
    
    private func animateSparkle() {
        withAnimation(.bouncy(duration: 0.5)) {
            scale = CGSize(width: 1.5, height: 1.5)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.bouncy(duration: 0.5)) {
                scale = CGSize(width: 1.0, height: 1.0)
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                animateSparkle()
            }
        }
    }
}

#Preview {
    PicPerfectPlusIcon()
}
