//
//  FinalSaveView.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 9/8/25.
//


import SwiftUI
import Photos

struct FinalSaveView: View {
    let results: [ImageOrientationResult]
    @Environment(\.dismiss) var dismiss

    @State private var deleteAlertPresent = false
    @State private var deleteOriginals = false
    @State private var selectedIndices: Set<Int> = []
   
    @Environment(ContentModel.self) var model
    
    var body: some View {
        NavigationView {
            VStack {
                Text("¿Quieres guardar estas fotos ya corregidas?")
                    .font(.title2)
                    .padding()

                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 10) {
                        ForEach(results.indices, id: \.self) { index in
                            Image(uiImage: results[index].image)
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

                Button("💾 Guardar seleccionadas") {
                    
                    deleteAlertPresent = true
                    
                   
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(12)
                .disabled(selectedIndices.isEmpty)
                .confirmationDialog("Delete Originals?", isPresented: $deleteAlertPresent, actions: {
                    Button("Save Only") {
                        deleteOriginals = false
                       savePhotos()
                    }
                    
                    Button("Save and Delete Originals", role: .destructive) {
                        deleteOriginals = true
                        savePhotos()
                    }
                    
                    Button("Cancel", role: .cancel) {}
                }, message: {
                    Text("Do you want to delete the original photos after saving the corrected versions?")
                })
            }
            .navigationTitle("¡Listo!")
        }
    }
    
    func savePhotos() {
        
        var selectedResults: [ImageOrientationResult] = []
        
        for index in selectedIndices {
            selectedResults.append(results[index])
        }
        
        Service.saveAndReplace(results: selectedResults) { saved in
            if saved {
                print("Photos saved successfully")
            } else {
                print("Error saving photos")
            }
        }
        dismiss()
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
