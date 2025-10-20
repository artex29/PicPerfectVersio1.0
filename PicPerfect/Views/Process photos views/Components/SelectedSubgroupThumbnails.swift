//
//  SelectedSubgroupThumbnails.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 10/17/25.
//

import SwiftUI

struct SelectedSubgroupThumbnails: View {
    @Binding var subGroup:[ImageInfo]
    @State private var selectedImage: ImageInfo? = nil
    @State private var groupToShow: [ImageInfo] = []
    
    var body: some View {
        
        ScrollView(.horizontal) {
            HStack {
                ForEach(groupToShow.reversed(), id: \.id) { image in
                    ZStack {
#if os(iOS)
                        Image(uiImage: image.image)
                            .resizable()
                            .frame(width: 60, height: 60)
                            .scaledToFill()
                            .clipShape(RoundedRectangle(cornerRadius: 8))
#elseif os(macOS)
                        Image(nsImage: image.image)
                            .resizable()
                            .frame(width: 50, height: 50)
                            .scaledToFill()
                            .clipShape(RoundedRectangle(cornerRadius: 8))
#endif
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(selectedImage == image ? Color.yellow : Color.clear, lineWidth: 2)
                    )
                    .onTapGesture {
                        selectedImage = image
                        showSelectedImage()
                    }
                }
            }
        }
        .scrollIndicators(.hidden)
        .padding(10)
        .onAppear {
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                selectedImage = subGroup.last
                groupToShow = subGroup
            }
            
        }
        .onChange(of: subGroup) { oldValue, newValue in
            if newValue.count != groupToShow.count  {
                groupToShow = newValue
            }
            
            let oldIDs = oldValue.map { $0.id }
            let newIDs = newValue.map { $0.id }
            
            for id in newIDs {
                if oldIDs.contains(id) == false {
                    if let newSelectedImage = newValue.last {
                        groupToShow = newValue
                        selectedImage = newSelectedImage
                        break
                    }
                }
            }
        }
    }
    
    private func showSelectedImage() {
        guard let selectedImage = selectedImage else { return }
        
        let lastPosition = subGroup.count - 1
        
        if let currentIndex = subGroup.firstIndex(where: { $0.id == selectedImage.id }) {
            if currentIndex != lastPosition {
                subGroup.remove(at: currentIndex)
                subGroup.append(selectedImage)
            }
        }
        
    }
}

#Preview {
    
    var subGroup:[ImageInfo] = [
        ImageInfo(isIncorrect: false, image: PPImage(named: "marquee1")!),
        ImageInfo(isIncorrect: false, image: PPImage(named: "marquee2")!),
        ImageInfo(isIncorrect: false, image: PPImage(named: "marquee3")!),
        ImageInfo(isIncorrect: false, image: PPImage(named: "marquee4")!),
        ImageInfo(isIncorrect: false, image: PPImage(named: "marquee5")!),
        ImageInfo(isIncorrect: false, image: PPImage(named: "marquee6")!)
        
    ]
    
    SelectedSubgroupThumbnails(subGroup: .constant(subGroup))
}
