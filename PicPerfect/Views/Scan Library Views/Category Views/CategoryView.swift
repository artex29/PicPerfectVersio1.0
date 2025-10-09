//
//  CategoryView.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 10/6/25.
//

import SwiftUI
import Photos

struct CategoryView: View {
    
    @Binding var selectedGroup: [PhotoGroup]?
    var photoGroups: [[PhotoGroup]]
    
    let device = DeviceHelper.type
    
    let onClose: () -> Void
    
    var body: some View {
        
        if device == .iPhone {
            NavigationStack {
                ZStack {
                    PicPerfectTheme.Colors.background
                        .ignoresSafeArea()
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            
                            ForEach(photoGroups, id: \.self) { group in
                                
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
                .navigationTitle("Categories")
                .toolbar(content: {
                    Button("Close", action: {onClose()})
                        .ifAvailableGlassButtonStyle()
                })
                .navigationBarTitleDisplayMode(.inline)

            }
            
        }
        else {
            ZStack {
                PicPerfectTheme.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        ForEach(photoGroups, id: \.self) { group in
                            
                            CategoryCard(selectedGroup: $selectedGroup, group: group)
                        }
                        
                        
                    }
                    .padding()
                }
                
            }
        }
        
       
    }
}


#Preview {
    CategoryView(selectedGroup: .constant(nil), photoGroups: [], onClose: {})
        .environment(PhotoGroupManager())
}
