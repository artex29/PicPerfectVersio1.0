//
//  DuplicatesView.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 9/24/25.
//

import SwiftUI
import Photos

enum DecisionActions: Int {
    case delete
    case keep
    case undo
}

struct DuplicatesView: View {
    
    var duplicaGroups: [DuplicateGroup]
    
    @State private var images:[UIImage?] = [
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
    ]
    
    @State private var groupedImages: [[ImageOrientationResult]] = []
    
    @State private var selectedGroup: [ImageOrientationResult] = []
    
    @State private var keepPhotos: [ImageOrientationResult] = []
    
    @State private var deletePhotos: [ImageOrientationResult] = []
    
    @State private var refresh: Bool = true
    
    @State private var decisionAction: DecisionActions? = nil
    
    var selectedIDImage: String {
        selectedGroup.reversed().first?.id ?? ""
    }
    
    var body: some View {
        
        GeometryReader { geo in
            ZStack {
                
                PicPerfectTheme.Colors.background
                
                VStack {
                    DuplicatePhotos(
                        keepPhotos: $keepPhotos,
                        deletePhotos: $deletePhotos,
                        allGroups: $groupedImages,
                        selectedGroup: $selectedGroup,
                        proxy: geo,
                        decisionAction: $decisionAction,
                        selecteIDImage: selectedIDImage
                    )
                    .isPresent(refresh)
                    Spacer()
                }
               
                
                VStack {
                    Spacer()
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(groupedImages.indices, id: \.self) { groupIndex in
                                let group = groupedImages[groupIndex]
                                
                                let thumbnail = Image(uiImage: group.first?.image ?? UIImage())

                                thumbnail
                                    .resizable()
                                    .scaledToFill()
                                    .clipShape(RoundedRectangle(cornerRadius: 30))
                                    .frame(height: 150)
                                    .onTapGesture {
                                        selectGroup(group: group)
                                    }

                            }
                        }
                        .padding()
                        
                    }
                    
                    DecisionMenuView(
                        deleteAction: {handleDecisionAction(for: .delete)},
                        undoAction: {handleDecisionAction(for: .undo)},
                        keepAction: {handleDecisionAction(for: .keep)}
                    )
                }
                .padding(.bottom, 30)
                .task {
                    await getGroups {
                        selectedGroup = groupedImages.first?.reversed() ?? []
                    }
                }
            }
            .ignoresSafeArea()
        }
        
    }
    
    
    private func handleDecisionAction(for decision: DecisionActions) {
        
        let resultedImage = selectedGroup.reversed().first!
        
        switch decision {
            
        case .delete:
            decisionAction = .delete
            deleteFromGroup(image: resultedImage, allGroups: &groupedImages) { nextIndex in
                deletePhotos.append(resultedImage)
                selectNextGroup(nextIndex: nextIndex,
                                selectedGroup: &selectedGroup,
                                allGroups: groupedImages)
            }
            
            
        case .keep:
            decisionAction = .keep
            
            deleteFromGroup(image: resultedImage, allGroups: &groupedImages) { nextIndex in
               keepPhotos.append(resultedImage)
                selectNextGroup(nextIndex: nextIndex,
                                selectedGroup: &selectedGroup,
                                allGroups: groupedImages)
            }
            
            
            
        case .undo:
            decisionAction = .undo
            if let index = keepPhotos.firstIndex(where: { $0.id == resultedImage.id }) {
                keepPhotos.remove(at: index)
                selectedGroup.append(resultedImage)
            } else if let index = deletePhotos.firstIndex(where: { $0.id == resultedImage.id }) {
                deletePhotos.remove(at: index)
                selectedGroup.append(resultedImage)
            }
        }
    }
    
    
    private func selectGroup(group: [ImageOrientationResult]) {
        selectedGroup = group.reversed()
    }
    
    private func getGroups(completion: @escaping() -> Void) async {
        
        var groups: [[ImageOrientationResult]] = []
        
        if duplicaGroups.isEmpty == false {
            for group in duplicaGroups {
                
                var imageGroup: [ImageOrientationResult] = []
                
                for asset in group.assets {
                    // Convert PHAsset to Image
                    var result: ImageOrientationResult = ImageOrientationResult(isIncorrect: false, image: UIImage(), asset: asset)
                    
                    if let uiImage = await Service.requestImage(for: asset, size: CGSize(width: asset.pixelWidth, height: asset.pixelHeight)) {
                       
                        // Add image to the appropriate group
                        result.image = uiImage
                        
                        imageGroup.append(result)
                    }
                    
                    
                }
                
                if !imageGroup.isEmpty {
                    groups.append(imageGroup)
                }
            }
        }
        else {
            // If no duplicate groups, create dummy groups from local images
            let chunkSize = 3
            for i in stride(from: 0, to: images.count, by: chunkSize) {
                
                var result: ImageOrientationResult = ImageOrientationResult(isIncorrect: false, image: UIImage(), asset: PHAsset())
                
                let chunk = Array(images[i..<min(i + chunkSize, images.count)])
                
                var results: [ImageOrientationResult] = []
                
                for image in chunk {
                    result.image = image ?? UIImage()
                    results.append(result)
                }
                
                groups.append(results)
            }
        }
        
        groupedImages = groups
        completion()
    }
    
}

struct DuplicatePhotos: View {
    
    @State private var expanded: Bool = false
    
    @State private var rotations: [String: Double] = [:]
    
    // Rotación por gesto cuando está expandido
    @State private var dragRotations: [String: CGFloat] = [:]
    @State private var dragOffsets: [String: CGSize] = [:]
    
    @Binding var keepPhotos: [ImageOrientationResult]
    @Binding var deletePhotos: [ImageOrientationResult]
    @Binding var allGroups: [[ImageOrientationResult]]
    
    @Binding var selectedGroup: [ImageOrientationResult]
    
    var proxy: GeometryProxy
    
    @Binding var decisionAction: DecisionActions?
    
    var selecteIDImage: String
    
    var body: some View {
        
        //Not expanded Group View
        VStack {
            ZStack(alignment: .top) {
                
                ForEach(selectedGroup.indices, id: \.self) { index in
                    
                    let image = selectedGroup[index]
                    let identifier = image.id
                    
                    ZStack {
                        scaledImage(image: image, imageIdentifier: identifier)
                            .transition(.scale.combined(with: .opacity))
                            .onAppear {
                                
                                if !expanded {
                                    
                                    startRotation(for: index, identifier: identifier)
                                }
                            }
                        
                        if expanded && abs(dragRotations[identifier] ?? 0) != 15 {
                            DecisionCard(angle: dragRotations[identifier] ?? 0)
                        }
                        
                        
                    }
                    .onChange(of: selectedGroup) { oldValue, newValue in
                        startRotation(for: index, identifier: identifier)
                    }
                    .onChange(of: decisionAction) { oldValue, newValue in
                        if let action = newValue, action != .undo, identifier == selecteIDImage {
                            startDeletingAnimation(for: identifier)
                        }
                    }
                    
                    
                }
            }
            .padding(expanded ? 0 : 20)
            .padding(.top, expanded ? 0 : 100)
            .onTapGesture {
                withAnimation() {
                    expanded.toggle()
                }
            }
           
        }
        
    }
    
    private func startRotation(for index: Int, identifier: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + (Double(index) * 0.1)) {
            withAnimation {
                rotations[identifier] = Double(index) * -5.0
               
            }
        }
    }
    
    private func startDeletingAnimation(for identifier: String) {
        
        withAnimation(.easeIn(duration: 0.3)) {
            
            let angle = decisionAction == .keep ? 30.0 : -30.0
            let widthOffset = decisionAction == .keep ? 500.0 : -500.0
            
            dragRotations[identifier] = angle
            dragOffsets[identifier] = CGSize(width: widthOffset, height: 0)
            
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            selectedGroup.removeAll { $0.id == identifier } 
            decisionAction = nil
        }
    }
    
    @ViewBuilder
    private func scaledImage(image: ImageOrientationResult, imageIdentifier: String) -> some View {
        
        let resultedImage = image
        let img = Image(uiImage: resultedImage.image)
        
        if expanded == false {
            img
                .resizable()
                .scaledToFit()
                .frame(height: 300)
                .rotationEffect(Angle(degrees: rotations[imageIdentifier] ?? 0))
                .rotationEffect(Angle(degrees: dragRotations[imageIdentifier] ?? 0))
                .offset(dragOffsets[imageIdentifier] ?? .zero)
        }
        else {
            img
                .resizable()
                .scaledToFill()
                .frame(width: proxy.size.width, height: proxy.size.height * 1.15)
                .rotationEffect(Angle(degrees: dragRotations[imageIdentifier] ?? 0))
                .offset(dragOffsets[imageIdentifier] ?? .zero)
                                .gesture(
                                    DragGesture()
                                        .onChanged { value in
                                            let dragAmount = value.translation.width
                                            let angle = dragAmount / 20 // sensibilidad
                                            dragRotations[imageIdentifier] = max(-15, min(15, angle))
                                            dragOffsets[imageIdentifier] = value.translation
                                           
                                        }
                                        .onEnded { _ in
                                            guard let angle = dragRotations[imageIdentifier] else { return }
                                            
                                            withAnimation(.easeIn) {
                                                
                                                if angle > 10 {
                                                    // mantener
                                                    dragRotations[imageIdentifier] = 15
                                                    keepPhotos.append(resultedImage)
                                                    deleteFromGroup(image: resultedImage, allGroups: &allGroups) { nextIndex in
                                                        selectNextGroup(nextIndex: nextIndex,
                                                        selectedGroup: &selectedGroup,
                                                        allGroups: allGroups)
                                                    }
                                                } else if angle < -10 {
                                                    // eliminar
                                                    dragRotations[imageIdentifier] = -15
                                                    deletePhotos.append(resultedImage)
                                                    deleteFromGroup(image: resultedImage, allGroups: &allGroups) { nextIndex in
                                                        selectNextGroup(nextIndex: nextIndex,
                                                        selectedGroup: &selectedGroup,
                                                        allGroups: allGroups)
                                                    }
                                                } else {
                                                    // volver al centro
                                                    dragRotations[imageIdentifier] = 0
                                                    dragOffsets[imageIdentifier] = .zero
                                                }
                                            }
                                        }
                                )
                                .opacity(abs(dragRotations[imageIdentifier] ?? 0) == 15 ? 0 : 1) // fade al llegar ±15
            
            
            
        }
    }
}

#Preview {
    DuplicatesView(duplicaGroups: [])
}

fileprivate func deleteFromGroup(image: ImageOrientationResult,
                                 allGroups: inout [[ImageOrientationResult]],
                                 completion: @escaping (Int?) -> Void) {
    
    if let groupIndex = allGroups.firstIndex(where: { $0.contains(where: { $0.id == image.id }) }) {
        if let imageIndex = allGroups[groupIndex].firstIndex(where: { $0.id == image.id }) {
            
            allGroups[groupIndex].remove(at: imageIndex)
            
            if allGroups[groupIndex].isEmpty {
                allGroups.remove(at: groupIndex)
                let nextIndex = groupIndex < allGroups.count ? groupIndex : nil
                completion(nextIndex)
            } else {
                completion(groupIndex)
            }
            return
        }
    }
    completion(nil)
}

fileprivate  func selectNextGroup(nextIndex: Int?, selectedGroup: inout [ImageOrientationResult], allGroups: [[ImageOrientationResult]]) {
    
    guard let nextIndex else { return }
    
    if nextIndex < allGroups.count {
        
        if allGroups[nextIndex].count > 1 {
            selectedGroup = allGroups[nextIndex].reversed()
        }
        else {
            let index = (nextIndex > 0) ? nextIndex - 1 : nextIndex + 1
            selectedGroup = allGroups[index].reversed()
        }
    }
}
