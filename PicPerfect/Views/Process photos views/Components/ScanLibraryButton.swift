//
//  ScanLibraryButton.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 10/28/25.
//

import SwiftUI

struct ScanLibraryButton: View {
    
    @Environment(PhotoGroupManager.self) var manager
    @Environment(ContentModel.self) var model
    
    @State private var remainingTime: TimeInterval = 0
    @State private var timer: Timer?
    
    @State private var buttonText: String = "🔍 Scan Library"
    
    var body: some View {
        
        Text(buttonText)
            .onAppear {
                startTimer()
                
            }
            .onDisappear {
                timer?.invalidate()
            }
    }
    
    private func buttonTextString() {
       
        if remainingTime > 0 {
            withAnimation {
                buttonText = formattedTime(remainingTime)
            }
        }
        else {
            if manager.allGroups.isEmpty {
                withAnimation {
                    buttonText = "🔍 Scan Library"
                }
            }
            else {
                withAnimation {
                    buttonText = "✨ Continue Where You Left Off"
                }
            }
        }
    }
    
    private func startTimer() {
            updateRemainingTime()
            
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                updateRemainingTime()
                buttonTextString()
            }
        }
        
        private func updateRemainingTime() {
            let now = Date().timeIntervalSince1970
            remainingTime = max(0, ContentModel.nextScanDate - now)
        }
        
        private func formattedTime(_ interval: TimeInterval) -> String {
            let totalSeconds = Int(interval)
            let hours = totalSeconds / 3600
            let minutes = (totalSeconds % 3600) / 60
            let seconds = totalSeconds % 60
            
            if hours > 0 {
                return String(format: "Next scan in %02dh %02dm %02ds", hours, minutes, seconds)
            } else {
                return String(format: "Next scan in %02dm %02ds", minutes, seconds)
            }
        }
}

#Preview {
    ScanLibraryButton()
        .environment(PhotoGroupManager())
        .environment(ContentModel())
}
