//
//  CategoryView.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 10/6/25.
//

import SwiftUI
import Photos

struct CategoryView: View {
    
    @Environment(PhotoGroupManager.self) var manager
    
    @Binding var selectedGroup: [PhotoGroup]?
    var photoGroups: [PhotoGroup]
    
    let device = DeviceHelper.type
    
    let onClose: () -> Void
    
    var photosToReviewCount: String {
        let count = photoGroups.reduce(0) { $0 + $1.images.count }
        return count > 0 ? "\(count) Photos to review" : ""
    }
    
    var body: some View {
        
        if device == .iPhone {
            NavigationStack {
                ZStack {
                    PicPerfectTheme.Colors.background
                        .ignoresSafeArea()
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            
                            ForEach(reGroupByCategory(), id: \.self) { group in
                                
                                NavigationLink(value: group) {
                                    CategoryCard(selectedGroup: $selectedGroup, group: group)
                                        .foregroundStyle(.clear)
                                }
                                .navigationDestination(for: [PhotoGroup].self) { group in
                                    SwipeDecisionView(photoGroups: group)
                                }
                                
                                
                            }
                            
                            
                        }
                        .padding()
                    }
                    
                }
                .navigationTitle(photosToReviewCount)
                .toolbar(content: {
                    
                        Button("X", action: {onClose()})
                            .ifAvailableGlassButtonStyle()
                        
                    
                })
                .navigationBarTitleDisplayMode(.inline)

            }
            .environment(manager)
            
        }
        else {
            ZStack {
                PicPerfectTheme.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        ForEach(reGroupByCategory(), id: \.self) { group in
                            
                            CategoryCard(selectedGroup: $selectedGroup, group: group)
                        }
                        
                        
                    }
                    .padding()
                }
                
            }
            .environment(manager)
        }
        
       
    }
    
    
    
    private func reGroupByCategory() -> [[PhotoGroup]] {
        let categories = Dictionary(grouping: photoGroups, by: { $0.category })
        let sortOrder: [PhotoGroupCategory] = [.duplicates, .similars, .blurry, .exposure, .faces, .screenshots, .orientation]
        
        return categories.values.map { Array($0) }.sorted { first, second in
            guard let firstCategory = first.first?.category,
                  let secondCategory = second.first?.category,
                  let firstIndex = sortOrder.firstIndex(of: firstCategory),
                  let secondIndex = sortOrder.firstIndex(of: secondCategory) else {
                return false
            }
            return firstIndex < secondIndex
        }
    }
    
}


#Preview {
    CategoryView(selectedGroup: .constant(nil), photoGroups: [], onClose: {})
        .environment(PhotoGroupManager())
}
