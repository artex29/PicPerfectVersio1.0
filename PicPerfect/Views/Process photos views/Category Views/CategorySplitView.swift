//
//  CategorySplitView.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 10/6/25.
//

import SwiftUI
import Photos

struct CategorySplitView: View {
   
    @Environment(PhotoGroupManager.self) var manager
    @Environment(\.modelContext) private var context
    
    let onClose: () -> Void
    let device = DeviceHelper.type
    @State private var selectedGroup: [PhotoGroup]? = nil
    @State private var sideBarVisibility: NavigationSplitViewVisibility = .doubleColumn
   
    @State private var navigationPath: [NavigationDestination] = []
    
    var body: some View {
        
        Group {
            if device == .iPhone {
                
                NavigationStack(path: $navigationPath) {
                    
                    CategoryView(selectedGroup: $selectedGroup, photoGroups: manager.allGroups, onClose: {onClose()}, navigationPath: $navigationPath)
                        .navigationDestination(for: NavigationDestination.self) { destination in
                            switch destination {
                            case .categoryView:
                                EmptyView()
                            case .swipeDecisionView(let group):
                                SwipeDecisionView(photoGroups: group, navigationPath: $navigationPath)
                            case .orientationView(group: let group):
                                let images = group.flatMap { $0.images }
                                ReviewMisalignedPhotos(images: images, selectedGroup: $selectedGroup, navigationPath: $navigationPath)
                                    .onAppear {
                                        selectedGroup = group
                                    }
                            case .confirmationView(let group):
                                ConfirmationView(navigationPath: $navigationPath, photoGroups:  group)
                            case .saveView:
                                EmptyView()
                            case .cleanupView:
                                CleanupSummaryView(navigationPath: $navigationPath)
                                    .onDisappear {
                                        onClose()
                                    }
                            }
                        }
                }
                
                   
                
            } else {
                // iPad o iPhone horizontal → usa SplitView
                
                NavigationSplitView(columnVisibility: $sideBarVisibility) {
                    CategoryView(selectedGroup: $selectedGroup, photoGroups: manager.allGroups, onClose: {onClose()}, navigationPath: .constant([]))
                        .navigationTitle("Categories")
                        .navigationSplitViewColumnWidth(min: 400, ideal: 400)
                       
                } detail: {
                    ZStack {
                        
                        Color(PicPerfectTheme.Colors.background)
                            .ignoresSafeArea()
                        
                        if let group = selectedGroup {
                            NavigationStack(path: $navigationPath) {
                                if group.first?.category != .orientation {
                                    SwipeDecisionView(photoGroups: group, navigationPath: $navigationPath)
                                        .id(group.first?.id) // Force detail view refresh
                                        .navigationDestination(for: NavigationDestination.self) { destination in
                                            switch destination {
                                            case .categoryView:
                                                EmptyView()
                                            case .swipeDecisionView(_):
                                                EmptyView()
                                            case .orientationView(_):
                                                EmptyView()
                                            case .confirmationView(let group):
                                                ConfirmationView(navigationPath: $navigationPath, photoGroups:  group)
                                                    .onAppear {
                                                        sideBarVisibility = .detailOnly
                                                    }
                                                    .onDisappear {
                                                        if manager.allGroups.isEmpty == false {
                                                            sideBarVisibility = .all
                                                            
                                                            let groups = manager.allGroups
                                                            
                                                            selectedGroup = groups.filter { $0.category == groups.first?.category}
                                                        }
                                                    }
                                            case .saveView:
                                                EmptyView()
                                            case .cleanupView:
                                                CleanupSummaryView(navigationPath: $navigationPath)
                                                    .onDisappear {
                                                        onClose()
                                                    }
                                            }
                                        }
                                        
                                } else {
                                    NavigationStack(path: $navigationPath) {
                                        let images = group.flatMap { $0.images }
                                        ReviewMisalignedPhotos(images: images, selectedGroup: $selectedGroup, navigationPath: $navigationPath)
                                            .id(group.first?.id) // Force detail view refresh
                                        
                                    }
                                }
                                
                            }
                           
                        } else {
                            Text("Select a category")
                                .font(.headline)
                                .foregroundStyle(.white)
                        }
                    }
                }
                .navigationSplitViewStyle(.balanced)
                .toolbar {
                    Button("Close") {
                        onClose()
                        PersistenceService.savePendingGroups(context: context, from: manager)
                    }
                }
            }
        }
        .onChange(of: selectedGroup) { oldValue, newValue in
            if newValue != nil && device != .iPhone {
                if #unavailable(iOS 26, macOS 26) {
                    sideBarVisibility = .detailOnly
                }
            }
        }
        
    }
}

#Preview {
    // MARK: - Mock Data for Testing
    
    let mockImages: [PPImage] = [
        PPImage(named: "marquee1"),
        PPImage(named: "marquee2"),
        PPImage(named: "marquee3"),
        PPImage(named: "marquee4"),
        PPImage(named: "marquee5"),
        PPImage(named: "marquee6"),
        PPImage(named: "marquee7"),
        PPImage(named: "marquee8"),
        PPImage(named: "marquee9"),
        PPImage(named: "marquee10"),
        PPImage(named: "marquee11"),
        PPImage(named: "marquee12")
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
    
    CategorySplitView(onClose: {})
        .environment(PhotoGroupManager())
}
