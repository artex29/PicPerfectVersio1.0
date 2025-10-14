//
//  ReviewMisalignedPhotos.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 9/8/25.
//


import SwiftUI
import Photos

struct ReviewMisalignedPhotos: View {
    let images: [ImageInfo]
    @State private var selectedIndices: Set<Int> = []
    @State private var isProcessing = false
    @State private var showConfirmation = false
    @State private var processedImages: [ImageInfo] = []

    @Binding var showingReviewScreen: Bool
    
    let dummyImages = Array(repeating: ImageInfo(isIncorrect: true, image: PPImage(named: "marquee1")!, asset: nil), count: 12)
    
    var finalImages: [ImageInfo] {
        images.isEmpty ? dummyImages : images
    }
    
    var body: some View {
        
        ZStack {
            
            PicPerfectTheme.Colors.background.ignoresSafeArea()
            
            VStack {
                Text("These photos seem to be misaligned. Select the ones you want to fix.")
                    .foregroundColor(.white)
                    .font(.headline)
                    .padding()
                
                GeometryReader { geo in
                    ScrollView {
                        
                        let columnCount = Int(geo.size.width / 120)
                        let size = (geo.size.width / CGFloat(columnCount)) - 10
                        let columns = Array(repeating: GridItem(.fixed(size), spacing: 10), count: columnCount)
                        
                        LazyVGrid(columns: columns) {
                            ForEach(finalImages.indices, id: \.self) { index in
                                let img = finalImages[index]
                                ZStack {
#if os(iOS)
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
#elseif os(macOS)
                                    Image(nsImage: img.image)
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
#endif
                                }
                            }
                        }
                        .padding()
                    }
                }
                
                Button(action: processSelectedImages) {
                    Text("✨ Work your magic")
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
                        .font(.title3)
                    
                }
                .ifAvailableGlassButtonStyle()
                
                
                Spacer()
            }
            .sheet(isPresented: $showConfirmation, onDismiss: {
                
            }, content: {
                FinalSaveView(results: processedImages)
            })
        }
        .padding()
        
        
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
               
                let result:ImageInfo = finalImages[i]
            
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
    ReviewMisalignedPhotos(images: [], showingReviewScreen: .constant(false))
}
