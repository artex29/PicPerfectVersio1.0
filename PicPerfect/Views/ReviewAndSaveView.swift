//
//  ReviewAndSaveView.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 9/3/25.
//

import SwiftUI
import PhotosUI

struct ReviewAndSaveView: View {
    @Binding var correctedPhotos: [CorrectedPhoto]
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 16) {
                        ForEach($correctedPhotos) { $photo in
                            ZStack(alignment: .topTrailing) {
                                #if os(iOS)
                                Image(uiImage: photo.correctedImage)
                                    .resizable()
                                    .scaledToFit()
                                    .cornerRadius(12)
                                #elseif os(macOS)
                                Image(nsImage: photo.correctedImage)
                                    .resizable()
                                    .scaledToFit()
                                    .cornerRadius(12)
                                #endif
                                    

                                Button {
                                    photo.isSelected.toggle()
                                } label: {
                                    Image(systemName: photo.isSelected ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(.yellow)
                                        .padding(6)
                                }
                            }
                        }
                    }
                    .padding()
                }

                Button("Save Selected") {
                    saveSelectedPhotos()
                }
                .ifAvailableGlassButtonStyle()
                .padding(.bottom)
            }
            .navigationTitle("Review & Save")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .background(PicPerfectTheme.Colors.background)
        }
    }

    func saveSelectedPhotos() {
        let selected = correctedPhotos.filter { $0.isSelected }
        PHPhotoLibrary.shared().performChanges {
            for photo in selected {
                PHAssetChangeRequest.creationRequestForAsset(from: photo.correctedImage)
            }
        } completionHandler: { success, error in
            if success {
                print("Photos saved successfully")
                dismiss()
            } else if let error = error {
                print("Error saving photos: \(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    ReviewAndSaveView(correctedPhotos: .constant([]))
}
