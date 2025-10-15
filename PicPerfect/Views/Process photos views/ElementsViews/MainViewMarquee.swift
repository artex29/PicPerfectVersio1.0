//
//  MainViewMarquee.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 9/18/25.
//

import SwiftUI
internal import Combine

struct MainViewMarquee: View {
    
    @State private var images: [Image] = [
        Image("marquee1"),
        Image("marquee2"),
        Image("marquee3"),
        Image("marquee4"),
        Image("marquee5"),
        Image("marquee6"),
        Image("marquee7"),
        Image("marquee8"),
        Image("marquee9"),
        Image("marquee10"),
        Image("marquee11"),
        Image("marquee12")
    ]
    
    let timer = Timer
        .publish(every: 4, on: .main, in: .common)
        .autoconnect()
    
    @State private var movingForward = true
    @State private var currentIndex = 0
    @State private var foregroundColors: [Color] = [.black.opacity(0.9), .black.opacity(0.5), .clear, .clear, .clear, .clear]
    
    @Binding var showProcessedPhotos: Bool
    
    @Environment(ContentModel.self) private var model
    
    var body: some View {
        
        ZStack {
            
//            Color.black
//                .ignoresSafeArea()
            
            GeometryReader { geo in
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(images.indices, id: \.self) { index in
                                let image = images[index]
                                ZStack {
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: geo.size.width * 0.98, height: geo.size.height)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .shadow(color: .yellow.opacity(0.3), radius: 5)
                                        .overlay(content: {
                                            LinearGradient(colors: [.black.opacity(0.3), .clear.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                        })
                                        .blendMode(.difference)
                                        .scrollTransition(
                                            axis: .horizontal
                                        ) { content, phase in
                                            return content
                                                .offset(x: phase.value * -250)
                                        }
                                    
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .containerRelativeFrame(.horizontal)
                                
                                .id(index)
                            }
                        }
                    }
                    .onReceive(timer) { _ in
                        withAnimation(.smooth(duration: 2.0)) {
                            if showProcessedPhotos == false {
                                moveToNextElement(proxy: proxy)
                            }
                        }
                        
                    }
                }
            }
            
            LinearGradient(colors: changeGradientColors(), startPoint: .bottom, endPoint: .top)
        }
        .ignoresSafeArea()
        .task {
            if model.processedPhotos.isEmpty == false {
                images.removeAll()
                #if os(iOS)
                images = model.processedPhotos.map { Image(uiImage: $0)}
                #elseif os(macOS)
                images = model.processedPhotos.map { Image(nsImage: $0)}
                #endif
            }
        }
        .onChange(of: model.processedPhotos) { oldValue, newValue in
            if newValue.isEmpty == false {
                images.removeAll()
#if os(iOS)
                images = model.processedPhotos.map { Image(uiImage: $0)}
#elseif os(macOS)
                images = model.processedPhotos.map { Image(nsImage: $0)}
#endif
            }
        }
        
    }
    
    private func changeGradientColors() -> [Color] {
        var foregroundColors: [Color] = []
        
        withAnimation(.linear(duration: 1.0)) {
            if showProcessedPhotos {
                foregroundColors = [.black.opacity(0.9), .black.opacity(0.7)]
            
            }
            else {
                foregroundColors = [.black.opacity(0.9), .black.opacity(0.7), .black.opacity(0.6), .clear, .clear, .clear, .clear]
            }
            
            
        }
        
        return foregroundColors
    }
    
    private func moveToNextElement(proxy: ScrollViewProxy) {
        if movingForward {
            // Si estamos yendo hacia adelante
            currentIndex += 1
            // Si llegamos al último, invertimos la dirección
            if currentIndex == images.count - 1 {
                movingForward = false
            }
        } else {
            // Si estamos yendo hacia atrás
            currentIndex -= 1
            // Si llegamos al primero, invertimos la dirección
            if currentIndex == 0 {
                movingForward = true
            }
        }
        
        // Mover el scroll al índice actual
        proxy.scrollTo(currentIndex, anchor: .center)
    }
}

#Preview {
    MainViewMarquee(showProcessedPhotos: .constant(false))
        .environment(ContentModel())
       
}
