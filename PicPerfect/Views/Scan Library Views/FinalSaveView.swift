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
                        }
                    }
                }
                .padding()

                Button("💾 Guardar seleccionadas") {
                    Service.saveAndReplace(results: results) { saved in
                        if saved {
                            print("Photos saved successfully")
                        } else {
                            print("Error saving photos")
                        }
                    }
                    dismiss()
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .navigationTitle("¡Listo!")
        }
    }
}


#Preview {
    FinalSaveView(results: [])
}
