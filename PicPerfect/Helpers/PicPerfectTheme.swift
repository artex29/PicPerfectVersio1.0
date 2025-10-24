//
//  PicPerfectTheme.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 8/16/25.
//

import SwiftUI

struct PicPerfectTheme {
    struct Colors {
        static let background = Color(hex: "#0A0A0A")
        static let accent = Color(hex: "#FFD700")
        static let secondaryBackground = Color(hex: "#1A1A1A")
        static let mutedText = Color(hex: "#D9D9D9")
    }

    struct Fonts {
        static let title = Font.system(size: 28, weight: .bold, design: .default)
        static let body = Font.system(size: 16, weight: .regular)
        static let minimalist = Font.system(.headline, design: .rounded)
    }
}

extension View {
    func picPerfectButton() -> some View {
        self
            .foregroundColor(.black)
            .padding()
            .background(PicPerfectTheme.Colors.accent.opacity(0.5))
            .cornerRadius(12)
    }

    @ViewBuilder
    func ifAvailableGlassButtonStyle() -> some View {
        if #available(iOS 26, macOS 26, watchOS 26, visionOS 26, *) {
            self.buttonStyle(.glass)
        } else {
            self.picPerfectButton()
        }
    }
    
    @ViewBuilder
    func ifAvailableGlassContainer() -> some View {
        if #available(iOS 26, macOS 26, watchOS 26, visionOS 26, *) {
            GlassEffectContainer {
                self
                    .glassEffect(.clear, in: RoundedRectangle(cornerRadius: 10) )
                   
            }
        }
        else {
            self
                .background(.ultraThinMaterial)
        }
    }
    
    @ViewBuilder
    func disabledView(_ isDisabled: Bool) -> some View {
        if isDisabled {
            self.opacity(0.5)
                .allowsHitTesting(false)
                .disabled(true)
        } else {
            self
        }
    }
    
    @ViewBuilder
    func applyGlassIfAvailable() -> some View {
        if #available(iOS 26, macOS 26, watchOS 26, visionOS 26, *) {
            
            self
                .glassEffect(.clear, in: RoundedRectangle(cornerRadius: 10))
                
            
        } else {
            self
                .background(.ultraThinMaterial)
            
        }
    }
}

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#")

        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)

        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8) & 0xFF) / 255
        let b = Double(rgb & 0xFF) / 255

        self.init(red: r, green: g, blue: b)
    }
}

