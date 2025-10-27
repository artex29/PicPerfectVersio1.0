//
//  CategoryView.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 10/6/25.
//

import SwiftUI
import Photos

enum NavigationDestination: Hashable {
    case categoryView
    case orientationView(group: [PhotoGroup])
    case swipeDecisionView(group:[PhotoGroup])
    case confirmationView(group: [PhotoGroup])
    case saveView
    case cleanupView
}

struct CategoryView: View {
    
    @Environment(PhotoGroupManager.self) var manager
    @Environment(\.modelContext) private var context
    
    @Binding var selectedGroup: [PhotoGroup]?
    var photoGroups: [PhotoGroup]
    
    let device = DeviceHelper.type
    
    let onClose: () -> Void
    
    var photosToReviewCount: String {
        let count = photoGroups.reduce(0) { $0 + $1.images.count }
        return count > 0 ? "\(count) Photos to review" : ""
    }
    
    @Binding var navigationPath: [NavigationDestination]
   
    
    var body: some View {
        
        if device == .iPhone {
            
            
            ZStack {
                PicPerfectTheme.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        ForEach(reGroupByCategory(), id: \.self) { group in
                            
                            CategoryCard(selectedGroup: $selectedGroup, group: group)
                                .foregroundStyle(.clear)
                                .onTapGesture {
                                    if group.contains(where: {$0.category != .orientation}) {
                                        navigationPath.append(.swipeDecisionView(group: group))
                                        
                                    }
                                    else {
                                        //MARK: - Orientation category, create orientation screen and go there
                                        navigationPath.append(.orientationView(group: group))
                                    }
                                }
                        }
                        
                        
                    }
                    .padding()
                }
                
            }
            .environment(manager)
            .navigationTitle(photosToReviewCount)
            .toolbar(content: {
                
                Button("X", action: {
                    PersistenceService.savePendingGroups(context: context, from: manager)
                    onClose()
                })
                .ifAvailableGlassButtonStyle()
                
                
            })
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
              
            
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
        let sortOrder: [PhotoGroupCategory] = [.duplicates, .similars, .screenshots, .faces, .blurry, .exposure]
        
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
    CategoryView(selectedGroup: .constant(nil), photoGroups: [], onClose: {}, navigationPath: .constant([]))
        .environment(PhotoGroupManager())
}
