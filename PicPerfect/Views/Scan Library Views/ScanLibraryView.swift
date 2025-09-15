//
//  ScanLibraryView.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 9/8/25.
//


import SwiftUI
import PhotosUI

struct ScanLibraryView: View {
    @State private var scannedImages: [ImageOrientationResult] = []
    @State private var showingReviewScreen = false
    @State private var isScanning = false
    @State private var photoAccessGranted = false
    
    @State private var permisionAlertPresented = false
    
    var body: some View {
        VStack(spacing: 20) {
            if isScanning {
                ProgressView("Scanning Library…")
            } else {
                Button(action: scanLibrary) {
                    Text("🔍 Scan Library")
                        .font(.title2)
                        .padding()
                        .background(Color.blue.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
        }
        .padding()
        .onAppear {
            Service.requestPhotoLibraryAccessIfNeeded { granted in
                photoAccessGranted = granted
            }
        }
        .fullScreenCover(isPresented: $showingReviewScreen) {
            ReviewCorrectedImagesView(images: scannedImages)
        }
        .alert("Permission Required", isPresented: $permisionAlertPresented) {
            
            Button("Open Settings") {
                if let appSettings = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(appSettings)
                }
            }
            
            Button("Cancel", role: .cancel) {}
            
        } message: {
            Text("Please grant photo access in Settings to continue.")
        }

    }

    func scanLibrary() {
        
        if photoAccessGranted {
            
            isScanning = true
            
            Task {
                let images = await PhotoLibraryScanner.shared.scanForIncorrectlyOrientedPhotos(limit: 5)
                scannedImages = images
                isScanning = false
                showingReviewScreen = true
            }
        } else {
            permisionAlertPresented = true
        }
    }
}

#Preview {
    ScanLibraryView()
}
