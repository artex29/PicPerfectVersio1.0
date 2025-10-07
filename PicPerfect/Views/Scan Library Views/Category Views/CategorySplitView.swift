//
//  CategorySplitView.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 10/6/25.
//

import SwiftUI
import Photos

struct CategorySplitView: View {
    
    let photoGroups: [[PhotoGroup]]
    let onClose: () -> Void
    let device = DeviceHelper.type
    @State private var selectedGroup: [PhotoGroup]? = nil
    @State private var sideBarVisibility: NavigationSplitViewVisibility = .doubleColumn
   
    
    var body: some View {
        
        Group {
            if device == .iPhone {
           
                    CategoryView(selectedGroup: $selectedGroup, photoGroups: photoGroups)
                        .navigationTitle("Categories")
                        .toolbar {
                            Button("Close") { onClose() }
                        }
                        
              
            } else {
                // iPad o iPhone horizontal → usa SplitView
                
                NavigationSplitView(columnVisibility: $sideBarVisibility) {
                    CategoryView(selectedGroup: $selectedGroup, photoGroups: photoGroups)
                        .navigationTitle("Categories")
                        .navigationSplitViewColumnWidth(min: 400, ideal: 400)
                       
                } detail: {
                    if let group = selectedGroup {
                        SwipeDecisionView(photoGroups: group)
                            .id(group.first?.id ?? UUID()) // Force detail view refresh
                    } else {
                        Text("Select a category")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                }
                .navigationSplitViewStyle(.balanced)
                .toolbar {
                    Button("Close") { onClose() }
                }
            }
        }
        .onChange(of: selectedGroup) { oldValue, newValue in
            if newValue != nil && device != .iPhone {
                sideBarVisibility = .detailOnly
            }
        }
        
    }
}

#Preview {
    // MARK: - Mock Data for Testing
    
    let mockImages: [UIImage] = [
        UIImage(named: "marquee1"),
        UIImage(named: "marquee2"),
        UIImage(named: "marquee3"),
        UIImage(named: "marquee4"),
        UIImage(named: "marquee5"),
        UIImage(named: "marquee6"),
        UIImage(named: "marquee7"),
        UIImage(named: "marquee8"),
        UIImage(named: "marquee9"),
        UIImage(named: "marquee10"),
        UIImage(named: "marquee11"),
        UIImage(named: "marquee12")
    ].compactMap { $0 }
    
    // Fake PHAsset placeholder
    let dummyAsset = PHAsset()
    
    // Convert each UIImage into ImageInfo
    var mockImageInfos: [ImageInfo] {
        
      
        return mockImages.map { img in
            ImageInfo(
                isIncorrect: false,
                image: img,
                asset: PHAsset(),
                summary: nil,
                imageType: nil,
                orientation: nil,
                rotationAngle: nil,
                confidence: nil,
                source: "Mock"
            )
        }
    }
    
    // Create mock groups by category
    var photoGroups: [[PhotoGroup]] {
        [
            [PhotoGroup(
                images: Array(mockImageInfos.prefix(4)),
                score: 0.12,
                category: .duplicates
            ),
             PhotoGroup(
                 images: Array(mockImageInfos.prefix(4)),
                 score: 0.12,
                 category: .duplicates
             )],
            [PhotoGroup(
                images: Array(mockImageInfos[4..<8]),
                score: 0.7,
                category: .blurry
            )],
            [PhotoGroup(
                images: Array(mockImageInfos[8..<12]),
                score: 0.3,
                category: .faces
            )],
            [PhotoGroup(
                images: Array(mockImageInfos[5..<8]),
                score: 0.3,
                category: .screenshots
            )]
        ]
    }
    
    CategorySplitView(photoGroups: photoGroups, onClose: {})
}
