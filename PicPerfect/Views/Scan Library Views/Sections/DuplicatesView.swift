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
    
    @State private var groupedImages: [[ImageInfo]] = []
    
    @State private var selectedGroup: [ImageInfo] = []
    
    @State private var keepPhotos: [ImageInfo] = []
    
    @State private var deletePhotos: [ImageInfo] = []
    
    @State private var decisionAction: DecisionActions? = nil
    
    @State private var decisionHistory: [DecisionRecord] = []
    
    @State private var refresh = true
    
    var selectedIDImage: String {
        let id = selectedGroup.reversed().first?.id ?? ""
        print("Selected ID Image: \(id)")
        return id
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
                        selectedIDImage: selectedIDImage
                    )
                    .isPresent(refresh)
                    .onChange(of: decisionAction) { oldValue, newValue in
                        guard newValue != nil else { return  }
                        
                        if newValue == .undo {
                            // force a refresh to reset any animation glitches
                            refresh = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                                refresh = true
                            }
                        }
                    }
                   
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
                        keepAction: {handleDecisionAction(for: .keep)},
                        decisionHistory: decisionHistory
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
            
            if let rec = makeRecord(for: resultedImage, action: .delete) {
                decisionHistory.append(rec)
            }
            
            decisionAction = .delete
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.40) {
                deleteFromGroup(image: resultedImage, allGroups: &groupedImages) { nextIndex, returningGroups in
                    deletePhotos.append(resultedImage)
                    selectNextGroup(nextIndex: nextIndex,
                                    selectedGroup: &selectedGroup,
                                    allGroups: returningGroups ?? [])
                }
            }
            
           
            
        case .keep:
            
            if let rec = makeRecord(for: resultedImage, action: .keep) {
                decisionHistory.append(rec)
            }
            
            decisionAction = .keep
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.40) {
                deleteFromGroup(image: resultedImage, allGroups: &groupedImages) { nextIndex, returningGroups in
                    keepPhotos.append(resultedImage)
                    selectNextGroup(nextIndex: nextIndex,
                                    selectedGroup: &selectedGroup,
                                    allGroups: returningGroups ?? [])
                }
            }
            
            
            
        case .undo:
            decisionAction = .undo
            undoLastAction()
           
        }
    }
    
    private func undoLastAction() {
        guard let last = decisionHistory.popLast() else { return }
        guard decisionAction != nil else { return }
        
        // 1) Quitar de keep/delete
        if last.action == .keep {
            if let idx = keepPhotos.firstIndex(where: { $0.id == last.image.id }) {
                keepPhotos.remove(at: idx)
            }
        } else if last.action == .delete {
            if let idx = deletePhotos.firstIndex(where: { $0.id == last.image.id }) {
                deletePhotos.remove(at: idx)
            }
        }
        
        // 2) Buscar el grupo original (sin la imagen removida)
        let remainingIds = Set(last.originalGroupIds.filter { $0 != last.image.id })
        
        let sampleID = remainingIds.first
        
        if let groupIndex = groupedImages.firstIndex(where: {$0.contains(where: {$0.id == sampleID})}) {
            let position = min(last.originalImageIndex, groupedImages[groupIndex].count)
            groupedImages[groupIndex].insert(last.image, at: position)
            selectedGroup = groupedImages[groupIndex].reversed()
        }
        else {
            let groupPosition = min(last.originalGroupIndex, groupedImages.count)
            groupedImages.insert([last.image], at: groupPosition)
            selectedGroup = groupedImages[groupPosition].reversed()
        }
    }
    
    
    private func selectGroup(group: [ImageInfo]) {
        selectedGroup = group.reversed()
    }
    
    private func getGroups(completion: @escaping() -> Void) async {
        
        var groups: [[ImageInfo]] = []
        
        if duplicaGroups.isEmpty == false {
            for group in duplicaGroups {
                
                var imageGroup: [ImageInfo] = []
                
                for asset in group.assets {
                    // Convert PHAsset to Image
                    var result: ImageInfo = ImageInfo(isIncorrect: false, image: UIImage(), asset: asset)
                    
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
                
                var result: ImageInfo = ImageInfo(isIncorrect: false, image: UIImage(), asset: PHAsset())
                
                let chunk = Array(images[i..<min(i + chunkSize, images.count)])
                
                var results: [ImageInfo] = []
                
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
    
    private func makeRecord(for image: ImageInfo,
                            action: DecisionActions) -> DecisionRecord? {
        
        guard let gIdx = groupedImages.firstIndex(where: { $0.contains(where: { $0.id == image.id }) }),
              let iIdx = groupedImages[gIdx].firstIndex(where: { $0.id == image.id }) else { return nil }
        
        let groupIds = groupedImages[gIdx].map { $0.id }   // estado previo
        return DecisionRecord(action: action,
                              image: image,
                              originalGroupIndex: gIdx,
                              originalImageIndex: iIdx,
                              originalGroupIds: groupIds)
    }
    
}

struct DuplicatePhotos: View {
    
    @State private var expanded: Bool = false
    
    @State private var rotations: [String: Double] = [:]
    
    // Rotación por gesto cuando está expandido
    @State private var dragRotations: [String: CGFloat] = [:]
    @State private var dragOffsets: [String: CGSize] = [:]
    
    @Binding var keepPhotos: [ImageInfo]
    @Binding var deletePhotos: [ImageInfo]
    @Binding var allGroups: [[ImageInfo]]
    
    @Binding var selectedGroup: [ImageInfo]
    
    var proxy: GeometryProxy
    
    @Binding var decisionAction: DecisionActions?
    
    var selectedIDImage: String
    
    var body: some View {
        
        //Not expanded Group View
        VStack {
            ZStack(alignment: .top) {
                
                ForEach(Array(selectedGroup.enumerated()), id: \.element.id) { index, image in
                    
                    
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
                        
                        if let action = newValue, action != .undo , identifier == selectedIDImage {
                            
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
    private func scaledImage(image: ImageInfo, imageIdentifier: String) -> some View {
        
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
                                                    // keep
                                                    dragRotations[imageIdentifier] = 15
                                                    decisionAction = .keep
                                                    
                                                } else if angle < -10 {
                                                    // delete
                                                    dragRotations[imageIdentifier] = -15
                                                    decisionAction = .delete

                                                } else {
                                                    // get it back to center
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

fileprivate func deleteFromGroup(image: ImageInfo,
                                 allGroups: inout [[ImageInfo]],
                                 completion: @escaping (Int?, _ returningGroups: [[ImageInfo]]?) -> Void) {
    
    if let groupIndex = allGroups.firstIndex(where: { $0.contains(where: { $0.id == image.id }) }) {
        if let imageIndex = allGroups[groupIndex].firstIndex(where: { $0.id == image.id }) {
            
            allGroups[groupIndex].remove(at: imageIndex)
            
            if allGroups[groupIndex].isEmpty {
                allGroups.remove(at: groupIndex)
                let nextIndex = groupIndex < allGroups.count ? groupIndex : nil
                completion(nextIndex, allGroups)
            } else {
                completion(groupIndex, allGroups)
            }
            return
        }
    }
    completion(nil, nil)
}

fileprivate  func selectNextGroup(nextIndex: Int?, selectedGroup: inout [ImageInfo], allGroups: [[ImageInfo]]) {
    
    guard let nextIndex else { return }
    
    if nextIndex < allGroups.count {
        
        if allGroups[nextIndex].count > 0 {
            selectedGroup = allGroups[nextIndex].reversed()
        }
        else {
            let index = (nextIndex > 0) ? nextIndex - 1 : nextIndex + 1
            selectedGroup = allGroups[index].reversed()
        }
    }
}
