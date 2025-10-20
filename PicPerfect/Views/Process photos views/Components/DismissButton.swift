//
//  DismissButton.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 10/15/25.
//

import SwiftUI

struct DismissButton: View {
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        HStack {
            Spacer()
            
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
            }
            .ifAvailableGlassButtonStyle()

        }
        .padding(10)
    }
}

#Preview {
    DismissButton()
}
