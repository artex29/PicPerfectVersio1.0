//
//  CategoryCard.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 10/6/25.
//

import SwiftUI

struct CategoryCard: View {
    
    @Binding var selectedGroup: [PhotoGroup]?
    var group: [PhotoGroup]
    
    let device = DeviceHelper.type
    
    var body: some View {
        if device == .iPhone {
            iPhoneCategoryCard(group: group)
                
        }
        else {
            iPadCategoryCard(selectedGroup: $selectedGroup, group: group)
        }
    }
}


struct iPhoneCategoryCard: View {
    
    var group: [PhotoGroup]
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 10)
                .applyGlassIfAvailable()
            
            let firstGroup = group.first ?? PhotoGroup(images: [], score: nil, category: .blurry)
            let totalCount = group.reduce(0) { $0 + $1.images.count }
            
            VStack(alignment: .leading) {
                
                HStack {
                    
                    Text("\(totalCount)")
                    
                    Text(firstGroup.category.displayName)
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right")
                }
                .foregroundStyle(.white)
                
                
                HStack {
                    ForEach(firstGroup.images.prefix(4), id: \.self) { image in
                        
#if os(iOS)
                        let img = Image(uiImage: image.image)
#elseif os(macOS)
                        let img = Image(nsImage: image.image)
#endif
                        
                        img
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipped()
                            .cornerRadius(5)
                    }
                }
                
            }
            .padding(10)
            
            
        }
    }
}


struct iPadCategoryCard: View {
    
    @Binding var selectedGroup: [PhotoGroup]?
    var group: [PhotoGroup]
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 10)
                .applyGlassIfAvailable()
            
            let firstGroup = group.first ?? PhotoGroup(images: [], score: nil, category: .blurry)
            let totalCount = group.reduce(0) { $0 + $1.images.count }
            
            VStack(alignment: .leading) {
                
                HStack {
                    
                    Text("\(totalCount)")
                    
                    Text(firstGroup.category.displayName)
                        .font(.caption)
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right")
                }
                .foregroundStyle(.white)
                
                
                HStack {
                    ForEach(firstGroup.images.prefix(4), id: \.self) { image in
                        
                        #if os(iOS)
                        let img = Image(uiImage: image.image)
                        #elseif os(macOS)
                        let img = Image(nsImage: image.image)
                        #endif
                        
                        img
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipped()
                            .cornerRadius(5)
                    }
                }
                
            }
            .padding(10)
            
        }
        .onTapGesture {
            selectedGroup = group 
        }
    }
}
#Preview {
    CategoryCard(selectedGroup: .constant(nil),
                 group: [])
    .environment(PhotoGroupManager())
}
