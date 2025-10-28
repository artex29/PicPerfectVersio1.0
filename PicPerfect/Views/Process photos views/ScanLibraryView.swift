//
//  ScanLibraryView.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 9/8/25.
//


import SwiftUI
import PhotosUI

struct ScanLibraryView: View {
    
    @Environment(ContentModel.self) private var model
    @Environment(PhotoGroupManager.self) private var manager
    @Environment(\.modelContext) private var context
    
    @State private var scannedImages: [ImageInfo] = []
  
    @State private var showingReviewScreen = false
    @State private var isScanning = false
    @State private var photoAccessGranted = false
    
    @State private var permisionAlertPresented = false
    
    @State private var progress: AnalysisProgress = .duplicates
    
    @State private var pendingGroups: [PhotoGroup]? = nil
    
    @State private var buttonText: String = "🔍 Scan Library"
    
    var onFinished:([PhotoGroup]) -> Void
    
    
    var body: some View {
        ZStack {
            
            PicPerfectTheme.Colors.background.ignoresSafeArea()
            
            MainViewMarquee()
            
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
                    
                    Spacer()
                    
                    Button(buttonText) {
                        if pendingGroups != nil {
                            onFinished(pendingGroups!)
                            
                        }
                        else {
                            
                            Service.requestPhotoLibraryAccessIfNeeded { granted in
                                photoAccessGranted = granted
                                Task {
                                    await analyzeLibrary()
                                }
                            }
                        }
                    }
                    .ifAvailableGlassButtonStyle()
                    
                }
            }
            .padding()
            .alert("Permission Required", isPresented: $permisionAlertPresented) {
                
                Button("Open Settings") {
#if os(iOS)
                    if let appSettings = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(appSettings)
                    }
#elseif os(macOS)
                    let privacyPhotosURL = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Photos")
                    let generalPrivacyURL = URL(string: "x-apple.systempreferences:com.apple.preference.security")
                    
                    if let url = privacyPhotosURL, NSWorkspace.shared.open(url) {
                        // ✅ Opened successfully
                    } else if let fallback = generalPrivacyURL {
                        NSWorkspace.shared.open(fallback)
                    }
#endif
                }
                
                Button("Cancel", role: .cancel) {}
                
            } message: {
                Text("Please grant photo access in Settings to continue.")
            }
        }
        .task {
//            PersistenceService.clearAllPendingGroups(context: context)
            if manager.allGroups.isEmpty == false {
                self.pendingGroups = manager.allGroups
                withAnimation {
                    buttonText = "✨ Continue Where You Left Off"
                }
            }
        }

    }
    
    private func analyzeLibrary() async {
        if photoAccessGranted {
            isScanning = true
            Task {
                
                let assets =  await Service.getLibraryAssets()
                let results = await PhotoLibraryScanner.analyzeLibraryWithEfficiency(assets: assets,
                                                                                     isUserSubscribed: model.isUserSubscribed) { prog in
                    print("Progress: \(prog.description) - \(Int(prog.percentage * 100))%")
                    
                    DispatchQueue.main.async {
                        progress = prog
                    }
                    
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
    ScanLibraryView(onFinished: {_ in })
        .environment(ContentModel())
        .environment(PhotoGroupManager())
}
