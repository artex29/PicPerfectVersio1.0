//
//  WelcomeView.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 10/24/25.
//

import SwiftUI

struct WelcomeView: View {
    
    private let images: [String] = [
        "marquee10",
        "marquee6",
        "marquee3",
        "marquee1",
        "marquee2",
        "marquee11"
        ]
        
    @State private var imageRotations:[Int: Angle] = [:]
    @State private var imagePositions:[Int: CGSize] = [:]
    
    var body: some View {
        
        VStack(spacing: 20) {
            Text("Make your photo library spotless 📸✨")
                .font(.title)
                .fontWeight(.bold)
                .shadow(color: .black, radius: 1, x: 2, y: 2)
            
            
            Text("PicPerfect helps you clean, organize, and perfect your photos — fast and effortlessly.")
                .shadow(color: .black, radius: 1, x: 2, y: 2)
           
            
            ZStack {
                ForEach(images.indices, id: \.self) { index in
                    let imageName = images[index]
                    Image(imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 200, height: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                        .onAppear {
                           
                            imageRotations[index] = .zero
                            imagePositions[index] = .zero
                            animate(for: index)
                        }
                        .offset(imagePositions[index] ?? .zero)
                        .rotationEffect(imageRotations[index] ?? .zero)
                        
                }
            }
            .padding()
            
            Spacer()
        }
        .multilineTextAlignment(.center)
        .foregroundStyle(.white)
        .padding()
        .ifAvailableGlassContainer()
        
    }
    
    private func animateRotation(for index: Int) {
        withAnimation(.easeInOut(duration: 1.0)) {
            if index.isMultiple(of: 2) {
                imageRotations[index] = Angle(degrees: Double(index) * 2.0)
            } else {
                imageRotations[index] = Angle(degrees: Double(index) * -2.0)
            }
        }
    }
    
    private func dismissPhotosAnimation() {
        
        for (index, _) in images.enumerated() {
            let angle = index.isMultiple(of: 2) ? Double(index) * 5.0 : Double(index) * -5.00
            
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(images.count - index) * 1.0) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    if angle >= 0 {
                        imageRotations[index] = Angle(degrees: 45)
                        imagePositions[index] = CGSize(width: 800, height: -200)
                    }
                    else {
                        imageRotations[index] = Angle(degrees: -45)
                        imagePositions[index] = CGSize(width: -800, height: -200)
                    }
                }
            }
        }
    }
    
    
    private func animate(for index: Int) {
        animateRotation(for: index)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            dismissPhotosAnimation()
        }
        
        let totalDuration = Double(images.count) * 1.0 + 2.0
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration) {
            withAnimation {
                imageRotations[index] = .zero
                imagePositions[index] = .zero
                animate(for: index)
            }
        }
    }
    
    
}

#Preview {
    WelcomeView()
}
