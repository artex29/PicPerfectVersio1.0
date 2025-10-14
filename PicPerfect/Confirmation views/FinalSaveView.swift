//
//  FinalSaveView.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 9/8/25.
//


import SwiftUI
import Photos

struct FinalSaveView: View {
    let results: [ImageInfo]
    @Environment(\.dismiss) var dismiss

    @State private var deleteAlertPresent = false
    @State private var deleteOriginals = false
    @State private var selectedIndices: Set<Int> = []
   
    @Environment(ContentModel.self) var model
    
    var body: some View {
        ZStack {
            
            PicPerfectTheme.Colors.background.ignoresSafeArea()
            
            VStack {
                
                HStack {
                    Spacer()
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                            .font(.title2)
                            
                    }
                    .ifAvailableGlassButtonStyle()
                    
                    
                }
                .padding(10)
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("Would you like to save the corrected photos?")
                            .foregroundColor(.white)
                            .font(.title2)
                            .padding(.bottom, 10)
                           
                        
                        Text("Tap on the photos you want to save, then click 'Save Selected'.")
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .padding()
                    
                    Spacer()
                }

                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 10) {
                        ForEach(results.indices, id: \.self) { index in
                            
                            #if os(iOS)
                            let image = Image(uiImage: results[index].image)
                            #elseif os(macOS)
                            let image = Image(nsImage: results[index].image)
                            #endif
                            
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipped()
                                .cornerRadius(8)
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

                Button("💾 Save Selected") {
                    
                    Task {
                        await savePhotos()
                    }
                   
                }
                .padding()
                .foregroundColor(.white)
                .cornerRadius(12)
                .disabled(selectedIndices.isEmpty)
                .ifAvailableGlassButtonStyle()
                .padding()
            }
            
        }
        .frame(minWidth: 400, minHeight: 600)
    }
    
    func savePhotos() async {
        
        var selectedResults: [ImageInfo] = []
        
        for index in selectedIndices {
            selectedResults.append(results[index])
        }
        
        await Service.saveAndReplace(results: selectedResults) { saved in
            if saved {
                dismiss()
                print("Photos saved successfully")
            } else {
                print("Error saving photos")
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
}


#Preview {
    FinalSaveView(results: [])
        .environment(ContentModel())
}
