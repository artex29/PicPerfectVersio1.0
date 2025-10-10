//
//  ConfirmationView.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 10/9/25.
//

import SwiftUI
import Photos

struct ConfirmationView: View {
    
    @Environment(PhotoGroupManager.self) private var manager
    
    @Binding var showingConfirmationView: Bool
    
    var photoGroups: [PhotoGroup]
    
    var actionsArray: [ConfirmationAction] {
        let category = photoGroups.first?.category ?? .duplicates
        return manager.confirmationActions.filter({ $0.category == category })
    }
    
    var confirmButtonTitle: String {
        let assetsToDelete = actionsArray.filter({ $0.action == .delete }).count
        return assetsToDelete > 0 ? "📸 Clean Up Now (\(assetsToDelete))" : "Done"
    }
    
    @State var dummyArray:[ConfirmationAction] = [
        ConfirmationAction(imageInfo: ImageInfo(isIncorrect: false, image: UIImage(named: "marquee1")!), action: .delete, category: .blurry),
        ConfirmationAction(imageInfo: ImageInfo(isIncorrect: false, image: UIImage(named: "marquee2")!), action: .keep, category: .duplicates),
        ConfirmationAction(imageInfo: ImageInfo(isIncorrect: false, image: UIImage(named: "marquee3")!), action: .keep, category: .exposure),
        ConfirmationAction(imageInfo: ImageInfo(isIncorrect: false, image: UIImage(named: "marquee4")!), action: .delete, category: .faces),
        ConfirmationAction(imageInfo: ImageInfo(isIncorrect: false, image: UIImage(named: "marquee5")!), action: .keep, category: .orientation),
        ConfirmationAction(imageInfo: ImageInfo(isIncorrect: false, image: UIImage(named: "marquee6")!), action: .delete, category: .screenshots),
        ConfirmationAction(imageInfo: ImageInfo(isIncorrect: false, image: UIImage(named: "marquee7")!), action: .keep, category: .similars),
        ConfirmationAction(imageInfo: ImageInfo(isIncorrect: false, image: UIImage(named: "marquee8")!), action: .delete, category: .blurry),
        ConfirmationAction(imageInfo: ImageInfo(isIncorrect: false, image: UIImage(named: "marquee9")!), action: .keep, category: .duplicates),
        ConfirmationAction(imageInfo: ImageInfo(isIncorrect: false, image: UIImage(named: "marquee10")!), action: .delete, category: .exposure),
        ConfirmationAction(imageInfo: ImageInfo(isIncorrect: false, image: UIImage(named: "marquee11")!), action: .keep, category: .faces),
        ConfirmationAction(imageInfo: ImageInfo(isIncorrect: false, image: UIImage(named: "marquee12")!), action: .delete, category: .orientation)
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
                                
                                Image(uiImage: action.imageInfo.image)
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
                    //.navigationTitle("Review & Confirm")
                }
                
                
                Button(confirmButtonTitle) {
                    // Perform cleanup action here
                    cleanUp()
                }
                .ifAvailableGlassButtonStyle()
                
            }
            
        }
        
       
    }
    
    private func toggleAction(for action: ConfirmationAction) {
        
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
        
        let assets = actionsArray.filter({ $0.action == .delete }).map({ $0.imageInfo.asset }).compactMap({ $0 })
        
        if !assets.isEmpty {
            Service.deleteAssets(assets) { success in
                if success {
                    manager.confirmationActions.removeAll(where: { assets.contains($0.imageInfo.asset ?? PHAsset()) })
                    showingConfirmationView = false
                }
            }
        }
        else {
            showingConfirmationView = false
        }
        
    }
    
}


#Preview {
    ConfirmationView(showingConfirmationView: .constant(true), photoGroups: [])
        .environment(PhotoGroupManager())
}
