//
//  ConfirmationView.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 10/9/25.
//

import SwiftUI
import Photos
import FirebaseAnalytics

struct ConfirmationView: View {
    
    @Environment(ContentModel.self) private var model
    @Environment(PhotoGroupManager.self) private var manager
    @Environment(\.modelContext) private var context
    
//    @Binding var showingConfirmationView: Bool
    @Binding var navigationPath: [NavigationDestination]
    
    var photoGroups: [PhotoGroup]
    
    var actionsArray: [ConfirmationAction] {
        let category = photoGroups.first?.category ?? .duplicates
        return manager.confirmationActions.filter({ $0.category == category })
    }
    
    var confirmButtonTitle: String {
        let assetsToDelete = actionsArray.filter({ $0.action == .delete }).count
        return assetsToDelete > 0 ? "📸 Clean Up Now (\(assetsToDelete))" : "Keep All Photos"
    }
    
    @State var dummyArray:[ConfirmationAction] = [
        ConfirmationAction(imageInfo: ImageInfo(isIncorrect: false, image: PPImage(named: "marquee1")!), action: .delete, category: .blurry),
        ConfirmationAction(imageInfo: ImageInfo(isIncorrect: false, image: PPImage(named: "marquee2")!), action: .keep, category: .duplicates),
        ConfirmationAction(imageInfo: ImageInfo(isIncorrect: false, image: PPImage(named: "marquee3")!), action: .keep, category: .exposure),
        ConfirmationAction(imageInfo: ImageInfo(isIncorrect: false, image: PPImage(named: "marquee4")!), action: .delete, category: .faces),
        ConfirmationAction(imageInfo: ImageInfo(isIncorrect: false, image: PPImage(named: "marquee5")!), action: .keep, category: .orientation),
        ConfirmationAction(imageInfo: ImageInfo(isIncorrect: false, image: PPImage(named: "marquee6")!), action: .delete, category: .screenshots),
        ConfirmationAction(imageInfo: ImageInfo(isIncorrect: false, image: PPImage(named: "marquee7")!), action: .keep, category: .similars),
        ConfirmationAction(imageInfo: ImageInfo(isIncorrect: false, image: PPImage(named: "marquee8")!), action: .delete, category: .blurry),
        ConfirmationAction(imageInfo: ImageInfo(isIncorrect: false, image: PPImage(named: "marquee9")!), action: .keep, category: .duplicates),
        ConfirmationAction(imageInfo: ImageInfo(isIncorrect: false, image: PPImage(named: "marquee10")!), action: .delete, category: .exposure),
        ConfirmationAction(imageInfo: ImageInfo(isIncorrect: false, image: PPImage(named: "marquee11")!), action: .keep, category: .faces),
        ConfirmationAction(imageInfo: ImageInfo(isIncorrect: false, image: PPImage(named: "marquee12")!), action: .delete, category: .orientation)
    ]
    
    var body: some View {
        ZStack {
            Color(PicPerfectTheme.Colors.background)
                .ignoresSafeArea()
            
            
            VStack {
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("Review & Confirm")
                            .font(.title2)
                            .bold()
                            .padding(.top, 10)
                            
                            .multilineTextAlignment(.leading)
                        
                        Text("Tap any photo to toggle between Keep and Delete")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            
                    }
                    .foregroundStyle(.white)
                    
                    Spacer()
                }
                .padding()
                
                GeometryReader { geo in
                    ScrollView {
                        
                        let columnCount = Int(geo.size.width / 140)
                        let size = (geo.size.width / CGFloat(columnCount)) - 10
                        let imageSize = CGSize(width: size, height: size)
                        
                        let columns = Array(repeating: GridItem(.fixed(size), spacing: 5), count: columnCount)
                        
                        LazyVGrid(columns: columns, spacing: 10) {
                            
                            ForEach(actionsArray, id: \.id) { action in
                                
                                #if os(iOS)
                                let image = Image(uiImage: action.imageInfo.image)
                                #elseif os(macOS)
                                let image = Image(nsImage: action.imageInfo.image)
                                #endif
                                
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: imageSize.width, height: imageSize.height)
                                    .overlay(alignment: .topTrailing) {
                                        Image(systemName: action.action == .keep ? "hand.thumbsup.fill" : "trash.slash.fill")
                                            .resizable()
                                            .scaledToFit()
                                            .foregroundStyle(action.action == .keep ? .green : .red)
                                            .padding(5)
                                            .opacity(0.8)
                                            .frame(height: 30)
                                            .background(
                                                Circle()
                                                    .opacity(0.5)
                                            )
                                            .padding(5)
                                            .padding(.trailing, 5)
                                        
                                    }
                                    .clipShape(.rect(cornerRadius: 3))
                                    .onTapGesture {
//                                        if let index = dummyArray.firstIndex(where: { $0.id == action.id }) {
//                                            withAnimation(.interactiveSpring) {
//                                                dummyArray[index].action = action.action == .keep ? .delete : .keep
//                                            }
//                                        }
                                        
                                        toggleAction(for: action)
                                    }
                                
                                
                            }
                            
                        }
                        
                        
                    }
                   
                }
                
                
                Button(confirmButtonTitle) {
                    // Perform cleanup action here
                    cleanUp()
                }
                .ifAvailableGlassButtonStyle()
                #if os(macOS)
                .padding()
                #endif
                
            }
            
        }
        .navigationBarBackButtonHidden()
        
       
    }
    
    private func toggleAction(for action: ConfirmationAction) {
        
        Analytics.logEvent("toggled_confirmation_action", parameters: [
            "category": action.category.rawValue,
            "new_action": action.action == .keep ? "delete" : "keep"
        ])
        
        if let index = manager.confirmationActions.firstIndex(where: { $0.id == action.id }) {
            var updatedAction = action
            updatedAction.action = action.action == .keep ? .delete : .keep
            withAnimation {
                manager.confirmationActions[index] = updatedAction
            }
           
        }
    }
    
    private func cleanUp() {
        // Implement cleanup logic here
        
        let assetsToDelete = actionsArray.filter({ $0.action == .delete }).map({ $0.imageInfo.asset }).compactMap({ $0 })
        let category = photoGroups.first?.category ?? .duplicates
        
        if !assetsToDelete.isEmpty {
            Service.deleteAssets(assetsToDelete) { success in
                if success {
                    endCleanUp()
                    PersistenceService.clearCompletedCategory(context: context, category: category)
                }
            }
        }
        else {
            endCleanUp()
            PersistenceService.clearCompletedCategory(context: context, category: category)
        }
        
        func endCleanUp() {
            for action in actionsArray {
                
                if let asset = action.imageInfo.asset {
                    
                    Task {
                        try await PhotoAnalysisCloudCache.markAsAnalyzed(asset, module: action.category)
                    }
                }
            }
            
            if manager.allGroups.isEmpty {
                navigationPath.append(.cleanupView)
            }
            else {
                
                Task {
                    await model.refreshSubscriptionStatus()
                    let remainingCategories = Set(manager.allGroups.map { $0.category })
                    let filteredCategories = remainingCategories.filter({model.plusCategories.contains($0) == false})
                    
                    if filteredCategories.isEmpty && model.isUserSubscribed == false {
                        navigationPath.append(.cleanupView)
                    }
                    else {
                        navigationPath.removeAll()
                    }
                }
            }
        }
    }
    
}


#Preview {
    ConfirmationView(navigationPath: .constant([]), photoGroups: [])
        .environment(PhotoGroupManager())
        .environment(ContentModel())
}
