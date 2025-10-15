//
//  ProcessedPhotos.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 9/18/25.
//

import SwiftUI

struct ProcessedPhotos: View {
   
    @Binding var showPhotos: Bool
    @State private var angle: Double = 90.0
   
    var body: some View {
        
        VStack {
            
            HStack {
                Spacer()
                
                Button {
                    
                   animate()
                    
                } label: {
                    ZStack {
                        
                        Image(systemName: "rectangle.portrait")
                            .resizable()
                            .scaledToFit()
                            .padding(.trailing, 10)
                            .frame(height: 25)
                        
                        Image(systemName: "photo")
                            .background()
                    }
                }
                .ifAvailableGlassButtonStyle()
            }
            
            Spacer()
            
            PhotosGrid(angle: angle)
                .isPresent(showPhotos)
            
        }
        .padding(5)
    }
    
    private func animate() {
        
        withAnimation(.easeIn(duration: 0.0)) {
            
            showPhotos.toggle()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                
                print("Animating to \(showPhotos ? "0" : "90") degrees")
                withAnimation {
                    if showPhotos {
                        
                        angle = 0.0
                    }
                    else {
                        angle = 90.0
                    }
                }
                
            }
        }
        
    }
    
}

struct PhotosGrid: View {
    
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
    
     var angle: Double
    
    @Environment(ContentModel.self) private var model
    
    var body: some View {
        ScrollView {

            let gridItems = Array(repeating: GridItem(.flexible(), spacing: 5), count: 2)

            LazyVGrid(columns: gridItems, alignment: .center) {
                ForEach(images.indices, id: \.self) { index in
                    images[index]
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .rotationEffect(Angle(degrees: angle))
                }
            }

        }
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
        
    }
}



#Preview {
    ProcessedPhotos(showPhotos: .constant(true))
        .environment(ContentModel())
}

