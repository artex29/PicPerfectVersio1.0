//
//  PermissionsView.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 10/25/25.
//

import SwiftUI
import Photos
import UserNotifications

struct PermissionsView: View {
    
    @Environment(ContentModel.self)  var model
    
    @Binding var photoAccessButtonPresent: Bool
    @Binding var notificationButtonPresent: Bool
    @State private var showNext = false
    @State private var isRequesting = false
    @State private var imagePositions: [Int: CGPoint] = [:]
    @State private var imageOpacity: [Int: Double] = [:]
    
    let images: [String] = [
        "marquee1",
        "marquee2",
        "marquee3",
        "marquee4",
        "marquee5",
        "marquee6",
        "marquee7",
        "marquee8",
        "marquee9",
        "marquee10",
        "marquee11",
        "marquee12"
    ]
    
    
    
    var body: some View {
        
        VStack(spacing: 20) {
            Text("Let’s get everything ready 📸🔔")
                .font(.title)
                .bold()
                .shadow(color: .black, radius: 1, x: 2, y: 2)
            
            Text("PicPerfect needs access to your photo library to find duplicates, blurry, or overexposed shots — and notifications to remind you to keep your gallery spotless.")
                .shadow(color: .black, radius: 1, x: 2, y: 2)
            
            GeometryReader { geo in
                ZStack {
                    ForEach(images.indices, id: \.self) { index in
                        let imageName = images[index]
                        Image(imageName)
                            .resizable()
                            .scaledToFill()
                            .frame(width: geo.size.width * 0.4, height: geo.size.width * 0.4)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(content: {
                                LinearGradient(colors: [.black.opacity(0.3), .clear.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            })
                            .position(imagePositions[index] ?? CGPoint(
                                x: CGFloat.random(in: 0...geo.size.width),
                                y: CGFloat.random(in: 0...geo.size.height)
                            ))
                            .opacity(imageOpacity[index] ?? Double.random(in: 0.1...1.0))
                            .onAppear {
                                withAnimation(.easeInOut(duration: 20).repeatForever(autoreverses: true)) {
                                    setImagePositions(for: index, geo: geo)
                                }
                                
                                withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                                    animateOpacity(for: index)
                                }
                            }
                            
                    }
                }
                
            }
            
            Spacer()
            
            if photoAccessButtonPresent {
                Button("Grant photo access") {
                    model.requestPhotoLibraryAccess { isGranted in
                        photoAccessButtonPresent = false
                        notificationButtonPresent = true
                    }
                }
                .ifAvailableGlassButtonStyle()
                
            }
            
            if notificationButtonPresent {
                Button("Notify me when cleanup is due") {
                    #if os(iOS)
                    model.reuqestNotificacionPermission { isGranted in
                        notificationButtonPresent = false
                    }
                    #elseif os(macOS)
                    notificationButtonPresent = false
                    
                    model.reuqestNotificacionPermission { isGranted in
                        
                    }
                    #endif
                }
                .ifAvailableGlassButtonStyle()
            }
           
           
        }
        .foregroundStyle(.white)
        .multilineTextAlignment(.center)
        .padding()
        .ifAvailableGlassContainer()
        
    }
    
    private func setImagePositions(for index: Int, geo: GeometryProxy) {
        let randomPosition = CGPoint(
            x: CGFloat.random(in: geo.size.width * 0.25...geo.size.width * 0.8),
            y: CGFloat.random(in: geo.size.height * 0.1...geo.size.height * 0.8)
        )
        
        imagePositions[index] = randomPosition
       
    }
    
    private func animateOpacity(for index: Int) {
        let randomOpacity = Double.random(in: 0.0...1.0)
        let finalOpacity = randomOpacity < 0.5 ? 0.0 : 1.0
        imageOpacity[index] = finalOpacity
    }
   
}

#Preview {
    PermissionsView(photoAccessButtonPresent: .constant(true), notificationButtonPresent: .constant(false))
        .environment(ContentModel())
}
