//
//  WelcomeView.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 8/16/25.
//

import SwiftUI

struct WelcomeView: View {
    @State private var isReady = false

    var body: some View {
        if isReady {
            ContentView()
        } else {
            ZStack {
                PicPerfectTheme.Colors.background.ignoresSafeArea()

                VStack(spacing: 32) {
                    Spacer()

                    Image(systemName: "photo.on.rectangle.angled")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundColor(PicPerfectTheme.Colors.accent)

                    Text(.makePhotos)
                        .multilineTextAlignment(.center)
                        .font(PicPerfectTheme.Fonts.title)
                        .foregroundColor(.white)
                        .padding(.horizontal)

                    Spacer()

                    Button(.getStarted) {
                        isReady = true
                    }
                    .ifAvailableGlassButtonStyle()
                }
                .padding()
            }
        }
    }
}

#Preview {
    WelcomeView()
}
