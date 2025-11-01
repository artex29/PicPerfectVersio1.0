//
//  CategoryCard.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 10/6/25.
//

import SwiftUI

struct CategoryCard: View {
    
    @Environment(ContentModel.self) var model
    
    @Binding var selectedGroup: [PhotoGroup]?
    
    var group: [PhotoGroup]
    
    let device = DeviceHelper.type
    
    var body: some View {
        if device == .iPhone {
            iPhoneCategoryCard(group: group)
                .overlay {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            PicPerfectPlusIcon()
                                
                        }
                    }
                    .padding(15)
                    .opacity(0.8)
                    .isPresent(model.plusCategories.contains(where: { group.first?.category == $0 }) )
                    
                }
                
        }
        else {
            iPadCategoryCard(selectedGroup: $selectedGroup, group: group)
                .overlay {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            PicPerfectPlusIcon()
                        }
                    }
                    .padding(15)
                    .opacity(0.8)
                    .isPresent(model.plusCategories.contains(where: { group.first?.category == $0 }) )
                    
                }
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
                    
                    firstGroup.category.icon
                        .resizable()
                        .scaledToFit()
                        .frame(height: 30)
                    
                    Text("\(totalCount)")
                    
                    Text(firstGroup.category.displayName)
                    
                    let totalSizeMB = group.reduce(0) { $0 + $1.images.reduce(0) { $0 + ($1.fileSizeInMB ?? 0.0)}}
                    
                    if totalSizeMB > 0 {
                        Text(String(format: "- %.2f MB", totalSizeMB))
                           
                    }
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right")
                }
                .foregroundStyle(.white)
                .font(.caption)
                
                
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
                    
                    firstGroup.category.icon
                        .resizable()
                        .scaledToFit()
                        .frame(height: 24)
                    
                    Text("\(totalCount)")
                    
                    Text(firstGroup.category.displayName)
                    
                    let totalSizeMB = group.reduce(0) { $0 + $1.images.reduce(0) { $0 + ($1.fileSizeInMB ?? 0.0)}}
                    
                    if totalSizeMB > 0 {
                        Text(String(format: "- %.2f MB", totalSizeMB))
                           
                    }
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right")
                }
                .foregroundStyle(.white)
                .font(.caption)
                
                
                
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
    .environment(ContentModel())
}
