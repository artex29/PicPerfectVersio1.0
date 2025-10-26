//
//  IntelligentDetectionView.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 10/24/25.
//

import SwiftUI
internal import Combine

struct SmartCategories: Identifiable {
    let id = UUID()
    var category: PhotoGroupCategory
    var images: [String]
    var categoryDisplayName: String {
        switch category {
        case .duplicates:
            return "🔁 Duplicates"
        case .blurry:
            return "🌫️ Blurry"
        case .exposure:
            return "🔆 Overexposed"
        case .screenshots:
            return "📱 Screenshots"
        default:
            return "📷 Other"
        }
    }
}

struct IntelligentDetectionView: View {
    
    // MARK: - States
    @State private var currentIndex: Int = 0
    @State private var movingForward: Bool = true
    
    // MARK: - Timer
    let timer = Timer
        .publish(every: 2.0, on: .main, in: .common)
        .autoconnect()
    
    private let smartCategories: [SmartCategories] = [
        SmartCategories(category: .duplicates, images: ["marquee3", "marquee3"]),
        SmartCategories(category: .blurry, images: ["marquee1"]),
        SmartCategories(category: .exposure, images: ["marquee2"]),
        SmartCategories(category: .screenshots, images: ["screenshot"])
    ]
    
    
    var body: some View {
        
        VStack(spacing: 20) {
            Text("Smart detection powered by AI 🤖")
                .font(.title)
                .bold()
                .shadow(color: .black, radius: 1, x: 2, y: 2)
            
            Text("Our technology detects duplicates, blurry images, overexposed shots, screenshots, and more — so you don’t have to.")
                .shadow(color: .black, radius: 1, x: 2, y: 2)
            
            GeometryReader { geo in
                HStack {
                    Spacer()
                    ForEach(smartCategories.indices, id:\.hashValue) { index in
                        let category = smartCategories[index]
                        VStack {
                            Text(category.categoryDisplayName)
                                .bold()
                                .shadow(color: .black, radius: 1, x: 2, y: 2)
                                .padding(.bottom, 40)
                            
                            ZStack {
                                ForEach(category.images.indices, id: \.self) { index in
                                    let imageName = category.images[index]
                                    
                                    switch category.category {
                                    case .duplicates:
                                        if index == 0 {
                                            Image(imageName)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 200, height: 300)
                                                .clipShape(RoundedRectangle(cornerRadius: 15))
                                                .rotationEffect(Angle(degrees: -15), anchor: .bottomLeading)
                                            
                                        }
                                        else {
                                            Image(imageName)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 200, height: 300)
                                                .clipShape(RoundedRectangle(cornerRadius: 15))
                                        }
                                    case .blurry:
                                        Image(imageName)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 200, height: 300)
                                            .clipShape(RoundedRectangle(cornerRadius: 15))
                                            .blur(radius: 5)
                                    case .exposure:
                                        Image(imageName)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 200, height: 300)
                                            .clipShape(RoundedRectangle(cornerRadius: 15))
                                            .overlay {
                                                Color.white.opacity(0.5)
                                            }
                                    case .screenshots:
                                        Image(imageName)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 200, height: 300)
                                            .clipShape(RoundedRectangle(cornerRadius: 15))
                                    default:
                                        EmptyView()
                                    }
                                    
                                    
                                }
                                
                            }
                            
                        }
                        .frame(width: geo.size.width )
                        
                        
                    }
                }
                .padding(.top)
                .offset(x: -CGFloat(currentIndex) * geo.size.width * 1.02) // Slide effect
                .animation(.easeInOut(duration: 0.7), value: currentIndex)
                .onReceive(timer) { _ in
                    withAnimation {
                        updateIndex()
                    }
                }
            }
            
            Spacer()
            
            
        }
        .foregroundStyle(.white)
        .multilineTextAlignment(.center)
        .padding()
        .ifAvailableGlassContainer()
    }
    
    // MARK: - Logic for cycling categories
        private func updateIndex() {
         
            if movingForward {
                if currentIndex < smartCategories.count - 1 {
                    currentIndex += 1
                } else {
                    movingForward = false
                    currentIndex -= 1
                }
            } else {
                if currentIndex > 0 {
                    currentIndex -= 1
                } else {
                    movingForward = true
                    currentIndex += 1
                }
            }
        }
}

#Preview {
    IntelligentDetectionView()
}
