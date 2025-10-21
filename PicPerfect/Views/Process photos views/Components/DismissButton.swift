//
//  DismissButton.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 10/15/25.
//

import SwiftUI

struct DismissButton: View {
    
    var dismissAction: () -> Void
    
    var body: some View {
        HStack {
            Spacer()
            
            Button {
                dismissAction()
            } label: {
                Image(systemName: "xmark")
            }
            .ifAvailableGlassButtonStyle()

        }
        .padding(10)
    }
}

#Preview {
    DismissButton(dismissAction: {})
}
