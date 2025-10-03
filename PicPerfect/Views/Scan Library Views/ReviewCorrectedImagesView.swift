//
//  ReviewCorrectedImagesView.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 9/8/25.
//


import SwiftUI
import Photos

struct ReviewCorrectedImagesView: View {
    let images: [ImageInfo]
    @State private var selectedIndices: Set<Int> = []
    @State private var isProcessing = false
    @State private var showConfirmation = false
    @State private var processedImages: [ImageInfo] = []

    @Binding var showingReviewScreen: Bool
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Estas fotos parecen estar mal orientadas. ¿Quieres arreglarlas?")
                    .font(.headline)
                    .padding()

                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 12) {
                        ForEach(images.indices, id: \.self) { index in
                            let img = images[index]
                            ZStack {
                                Image(uiImage: img.image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .clipped()
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(selectedIndices.contains(index) ? Color.green : Color.clear, lineWidth: 3)
                                    )
                                    .onTapGesture {
                                        toggleSelection(index: index)
                                    }
                            }
                        }
                    }
                    .padding()
                }

                Button(action: processSelectedImages) {
                    Text("✨ Haz la magia")
                        .font(.title3)
                        .padding()
                        .background(Color.purple.opacity(0.9))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(selectedIndices.isEmpty || isProcessing)
                
                Button {
                    showingReviewScreen = false
                } label: {
                    Text("Skip these photos")
                        .foregroundColor(.red)
                        .font(.title3)
                        
                }
                .picPerfectButton()


                Spacer()
            }
            .navigationTitle("Revisión")
            .fullScreenCover(isPresented: $showConfirmation) {
                FinalSaveView(results: processedImages)
            }
        }
    }

    func toggleSelection(index: Int) {
        if selectedIndices.contains(index) {
            selectedIndices.remove(index)
        } else {
            selectedIndices.insert(index)
        }
    }

    func processSelectedImages() {
        isProcessing = true
        
        Task {
            var corrected: [ImageInfo] = []
            
            for i in selectedIndices {
               
                let result:ImageInfo = images[i]
            
                var fixed = await OrientationService.correctedOrientation(for: result)
                
                fixed.isIncorrect = false
                
                corrected.append(fixed)
            }

            self.processedImages = corrected
            isProcessing = false
            showConfirmation = true
        }
    }
}


#Preview {
    ReviewCorrectedImagesView(images: [], showingReviewScreen: .constant(false))
}
