//
//  ContentView.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 8/16/25.
//

import SwiftUI
import PhotosUI

// ContentView remains the entry point after WelcomeView
struct ContentView: View {
    @State private var showPhotoPicker = false
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var correctedPhotos: [CorrectedPhoto] = []
    @State private var showReviewScreen = false
    @State private var correctedAlready = false
    @State private var photoAccessGranted = false
    
    var body: some View {
        Group {
            if photoAccessGranted {
                mainContent
            } else {
                Text("Please grant photo access in Settings to continue.")
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding()
            }
        }
        .onAppear {
            Service.requestPhotoLibraryAccessIfNeeded { granted in
                photoAccessGranted = granted
            }
        }
        .sheet(isPresented: $showReviewScreen, onDismiss: {
            correctedPhotos.removeAll()
            correctedAlready = false
        }, content: {
            ReviewAndSaveView(correctedPhotos: $correctedPhotos)
        })
        
    }

   

    var mainContent: some View {
        VStack {
            if correctedPhotos.isEmpty {
                Text("No corrected photos yet")
                    .foregroundColor(PicPerfectTheme.Colors.mutedText)
                    .font(PicPerfectTheme.Fonts.body)
                    .padding()
            } else {
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(correctedPhotos) { photo in
                            Image(uiImage: photo.correctedImage)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 200)
                                .cornerRadius(12)
                        }
                    }
                    .padding()
                }
            }

            Button("Select Photos") {
                showPhotoPicker = true
            }
            .ifAvailableGlassButtonStyle()
        }
        .navigationTitle("PicPerfect")
        .navigationBarTitleDisplayMode(.inline)
        .photosPicker(isPresented: $showPhotoPicker, selection: $selectedItems, maxSelectionCount: 5, matching: .images)
        .onChange(of: selectedItems) { oldValue, newItems in
            
            guard correctedAlready == false else { return }
            Task {
                await processSelectedPhotos {
                    DispatchQueue.main.async {
                        
                        showReviewScreen = true
                    }
                }
            }
        }
    }

    func processSelectedPhotos(completion: @escaping() -> Void) async {
        correctedPhotos.removeAll()

        for item in selectedItems {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                let corrected = await OrientationService.correctedOrientation(for: image)
                let model = CorrectedPhoto(correctedImage: corrected)
                correctedPhotos.append(model)
                print("Processed corrected photo")
            }
        }

        selectedItems.removeAll()
        print("Total corrected photos: \(correctedPhotos.count)")
        correctedAlready = true
        completion()
    }
    
   
}

#Preview {
    ContentView()
}
