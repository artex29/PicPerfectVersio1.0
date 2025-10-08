//
//  ScanLibraryView.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 9/8/25.
//


import SwiftUI
import PhotosUI

struct ScanLibraryView: View {
    
    @State private var scannedImages: [ImageInfo] = []
   // @State private var photoGroups: [[PhotoGroup]] = []
    @State private var showingReviewScreen = false
    @State private var isScanning = false
    @State private var photoAccessGranted = false
    
    @State private var permisionAlertPresented = false
    
    @State private var showProcessedPhotos = false
    
    @State private var progress: AnalysisProgress = .starting
    
    @Binding var navigationPath: NavigationPath
    //@Binding var photoGroups:[[PhotoGroup]]
    
    var onFinished:([[PhotoGroup]]) -> Void
    
    var body: some View {
        ZStack {
            
            PicPerfectTheme.Colors.background.ignoresSafeArea()
            
            MainViewMarquee(showProcessedPhotos: $showProcessedPhotos)
            
            VStack(spacing: 20) {
                
                if isScanning {
                    ProgressView("Scanning Library…")
                        .tint(.white)
                        .foregroundStyle(.white)
                    
                    ProgressView(value: progress.percentage, total: 1) {
                        Text(progress.description)
                    } currentValueLabel: {
                        Text("\(Int(progress.percentage * 100))%")
                    }
                    .tint(.white)
                    .foregroundStyle(.white)
                    
                    
                } else {
                    
                    ProcessedPhotos(showPhotos: $showProcessedPhotos)
                    
                    Spacer()
                    
                    Button("🔍 Scan Library") {
                        Task {
                            await analyzeLibrary()
                        }
                    }
                    .ifAvailableGlassButtonStyle()
                    
                }
            }
            .padding()
            .onAppear {
                
                
                Service.requestPhotoLibraryAccessIfNeeded { granted in
                    photoAccessGranted = granted
                }
            }
//            .fullScreenCover(isPresented: $showingReviewScreen, onDismiss: {
//                
//            }, content: {
//               CategorySplitView(photoGroups: photoGroups)
//            })
//            .fullScreenCover(isPresented: $showingReviewScreen) {
//                ReviewCorrectedImagesView(images: scannedImages, showingReviewScreen: $showingReviewScreen)
//            }
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

    }
    
    private func analyzeLibrary() async {
        if photoAccessGranted {
            isScanning = true
            Task {
                
                let assets =  await Service.getLibraryAssets()
                let results = await PhotoLibraryScanner.analyzeLibraryWithEfficiency(assets: assets) { prog in
                    print("Progress: \(prog.description) - \(Int(prog.percentage * 100))%")
                    
                    progress = prog
                    
                }
                
               // photoGroups = results
                
                isScanning = false
                print("➡️ Navigating to CategoryView with \(results.count) groups.")
                
               // showingReviewScreen = true
                onFinished(results)
            }
        }
        else {
            permisionAlertPresented = true
        }
    }
    
}

#Preview {
    ScanLibraryView(navigationPath: .constant(NavigationPath()), onFinished: {_ in })
        .environment(ContentModel())
}
