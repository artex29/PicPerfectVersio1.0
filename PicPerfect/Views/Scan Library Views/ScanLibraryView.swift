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
    @State private var duplicateGroups: [DuplicateGroup] = []
    @State private var showingReviewScreen = false
    @State private var isScanning = false
    @State private var photoAccessGranted = false
    
    @State private var permisionAlertPresented = false
    
    @State private var showProcessedPhotos = false
    
    var body: some View {
        ZStack {
            
            PicPerfectTheme.Colors.background.ignoresSafeArea()
            
            MainViewMarquee(showProcessedPhotos: $showProcessedPhotos)
            
            VStack(spacing: 20) {
                
                if isScanning {
                    ProgressView("Scanning Library…")
                        .tint(.white)
                        .foregroundStyle(.white)
                } else {
                    
                    ProcessedPhotos(showPhotos: $showProcessedPhotos)
                    
                    Spacer()
                    
                    Button(action: detectBadFaces) {
                        Text("🔍 Scan Library")
                            .font(PicPerfectTheme.Fonts.minimalist)
                        
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
//                DuplicatesView(duplicaGroups: duplicateGroups)
//            })
            .fullScreenCover(isPresented: $showingReviewScreen) {
                ReviewCorrectedImagesView(images: scannedImages, showingReviewScreen: $showingReviewScreen)
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

    }
    
    func detectBadFaces() {
        if photoAccessGranted {
            isScanning = true
            
            Task {
                let assets =  await Service.getLibraryAssets()
                let badFaces = await FaceQualityService.detectBadFaces(assets: assets)
                scannedImages = badFaces
                
                isScanning = false
                showingReviewScreen = true
            }
        }
        else {
            permisionAlertPresented = true
        }
    }
    
    private func detecExposure() {
        if photoAccessGranted {
            isScanning = true
            
            Task {
                let assets =  await Service.getLibraryAssets()
                let blurryPhotos = await ExposureService.detectExposureIssues(assets: assets)
                scannedImages = blurryPhotos
                
                isScanning = false
                showingReviewScreen = true
            }
        }
        else {
            permisionAlertPresented = true
        }
    }
    
    private func detectBlurryImages() {
        if photoAccessGranted {
            isScanning = true
            
            Task {
                let assets =  await Service.getLibraryAssets()
                let blurryPhotos = await BlurryPhotosService.detectBlurryPhotos(assets: assets)
                scannedImages = blurryPhotos
                
                isScanning = false
                showingReviewScreen = true
            }
        }
        else {
            permisionAlertPresented = true
        }

    }
    
    private func fetchScreenShots() {
        if photoAccessGranted {
            isScanning = true
            Task {
                let screenShots = await ScreenShotService.fetchScreenshotsBatch(limit: 100)
                
                // Filtrar nulos / ids inválidos
                let safeShots = screenShots.filter { !$0.asset.localIdentifier.isEmpty }
                
                
                scannedImages = safeShots
                isScanning = false
                
                
                // present only after UI updated
                
                showingReviewScreen = true
                
            }
        } else {
            permisionAlertPresented = true
        }
    }
    
    private func scanForDuplicates() {
        
        if photoAccessGranted {
            isScanning = true
            
            Task {
                let assets =  await Service.getLibraryAssets()
                
                let duplicates = try? await DuplicateService.detectDuplicates(assets: assets)
                
                duplicateGroups = duplicates ?? []
                print("Found \(duplicates?.count ?? 0) duplicate sets.")
                
                isScanning = false
                
                showingReviewScreen = true
            }
        } else {
            permisionAlertPresented = true
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
        .environment(ContentModel())
}
