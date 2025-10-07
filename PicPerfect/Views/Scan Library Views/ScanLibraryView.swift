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
                    
                    Button(action: analyzeLibrary) {
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
    
    private func analyzeLibrary() {
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
    
    func groupImages(category: PhotoGroupCategory, images: [ImageInfo]) async  {
        var result: [PhotoGroup] = []
       // var chunk: [ImageInfo] = []
        
        for image in images {
            result.append(PhotoGroup(images: [image], score: nil, category: category))
        }
        
//        let chunkSize:Int = images.count.isMultiple(of: 5) ? 5 : images.count % 5
//
//        for image in images {
//            chunk.append(image)
//            if chunk.count == chunkSize {
//                result.append(PhotoGroup(images: chunk, score: nil, category: category))
//                chunk.removeAll()
//            }
//        }
//        
//        if !chunk.isEmpty {
//            result.append(PhotoGroup(images: chunk, score: nil, category: category))
//        }
        
      //  photoGroups = result
    }
    
    func detectBadFaces() {
        if photoAccessGranted {
            isScanning = true
            
            Task {
                let assets =  await Service.getLibraryAssets()
                let badFaces = await FaceQualityService.detectBadFaces(assets: assets)
               // scannedImages = badFaces
                await groupImages(category: .faces, images: badFaces)
               
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
                let safeShots = screenShots.filter { $0.asset?.localIdentifier.isEmpty == false }
                
                
//                scannedImages = safeShots
                
                await groupImages(category: .screenshots, images: safeShots)
                
                isScanning = false
                
                
                // present only after UI updated
                
                showingReviewScreen = true
                
            }
        } else {
            permisionAlertPresented = true
        }
    }
    
//    private func scanForDuplicates() {
//        
//        if photoAccessGranted {
//            isScanning = true
//            
//            Task {
//                let assets =  await Service.getLibraryAssets()
//                
//                let duplicates = try? await DuplicateService.detectDuplicates(assets: assets)
//                
//                photoGroups = duplicates ?? []
//                print("Found \(duplicates?.count ?? 0) duplicate sets.")
//                
//                isScanning = false
//                
//                showingReviewScreen = true
//            }
//        } else {
//            permisionAlertPresented = true
//        }
//    }

    func scanLibrary() {
        
        if photoAccessGranted {
            
            isScanning = true
            
            Task {
                let images = await OrientationService.scanForIncorrectlyOrientedPhotos(limit: 5)
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
    ScanLibraryView(navigationPath: .constant(NavigationPath()), onFinished: {_ in })
        .environment(ContentModel())
}
