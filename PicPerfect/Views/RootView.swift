//
//  RootView.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 10/6/25.
//

import SwiftUI

struct RootView: View {
    var body: some View {
        HomeView()
    }
}

#Preview {
    RootView()
        .environment(ContentModel())
}
