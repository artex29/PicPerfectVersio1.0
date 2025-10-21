//
//  Extensions.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 9/5/25.
//

//import UIKit
import SwiftUI
import Photos


extension PPImage {
    
    
    var uniqueIdentifier: String {
#if os(iOS)
        return "\(size)\(scale)\(imageOrientation.rawValue)\(size.height > size.width)"
#elseif os(macOS)
        let rep = representations.first
        let width = rep?.pixelsWide ?? Int(size.width)
        let height = rep?.pixelsHigh ?? Int(size.height)
        let orientation = height > width ? "portrait" : "landscape"
        return "\(width)x\(height)_\(orientation)"
#endif
    }
    
    
    
    
#if os(iOS)
    /// iOS: accept PPImage.Orientation (UIImage.Orientation)
    static func exifOrientation(for orientation: PPImage.Orientation) -> Int {
        return Int(CGImagePropertyOrientation(orientation).rawValue)
    }
#else
    /// macOS: NSImage has no Orientation type; accept CGImagePropertyOrientation
    static func exifOrientation(for orientation: CGImagePropertyOrientation) -> Int {
        return Int(orientation.rawValue)
    }
#endif
    
    
    // MARK: - Fix Orientation
    func fixedOrientation() -> PPImage {
#if os(iOS)
        // --- iOS implementation ---
        guard let cgImage = self.cgImage else { return self }
        if self.imageOrientation == .up { return self }
        
        var transform = CGAffineTransform.identity
        
        switch self.imageOrientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: size.height)
            transform = transform.rotated(by: .pi)
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.rotated(by: .pi / 2)
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: size.height)
            transform = transform.rotated(by: -.pi / 2)
        default:
            break
        }
        
        switch self.imageOrientation {
        case .upMirrored, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        case .leftMirrored, .rightMirrored:
            transform = transform.translatedBy(x: size.height, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        default:
            break
        }
        
        guard let colorSpace = cgImage.colorSpace,
              let context = CGContext(
                data: nil,
                width: Int(size.width),
                height: Int(size.height),
                bitsPerComponent: cgImage.bitsPerComponent,
                bytesPerRow: 0,
                space: colorSpace,
                bitmapInfo: cgImage.bitmapInfo.rawValue
              ) else { return self }
        
        context.concatenate(transform)
        
        let drawRect: CGRect = self.isPortrait
        ? CGRect(x: 0, y: 0, width: size.height, height: size.width)
        : CGRect(x: 0, y: 0, width: size.width, height: size.height)
        
        context.draw(cgImage, in: drawRect)
        guard let newCGImage = context.makeImage() else { return self }
        return UIImage(cgImage: newCGImage)
        
#elseif os(macOS)
        // --- macOS implementation ---
        guard let tiffData = self.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else { return self }
        
        guard let cgImage = bitmap.cgImage else { return self }
        
        // En macOS no hay "orientación" como tal, pero podemos normalizar
        let newImage = NSImage(size: self.size)
        newImage.lockFocus()
        let rect = CGRect(origin: .zero, size: self.size)
        NSGraphicsContext.current?.cgContext.draw(cgImage, in: rect)
        newImage.unlockFocus()
        return newImage
#endif
    }
    
    // MARK: - Resize
    func resized(maxDimension: CGFloat = 1024) -> PPImage {
#if os(iOS)
        let originalSize = self.size
        let scale = min(maxDimension / originalSize.width,
                        maxDimension / originalSize.height,
                        1.0)
        let newSize = CGSize(width: originalSize.width * scale,
                             height: originalSize.height * scale)
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
#elseif os(macOS)
        let originalSize = self.size
        let scale = min(maxDimension / originalSize.width,
                        maxDimension / originalSize.height,
                        1.0)
        let newSize = CGSize(width: originalSize.width * scale,
                             height: originalSize.height * scale)
        
        let newImage = NSImage(size: newSize)
        newImage.lockFocus()
        self.draw(in: CGRect(origin: .zero, size: newSize),
                  from: .zero,
                  operation: .copy,
                  fraction: 1.0)
        newImage.unlockFocus()
        return newImage
#endif
    }
    
    // MARK: - Orientation helpers
    var isPortrait: Bool {
#if os(iOS)
        return self.imageOrientation == .left ||
        self.imageOrientation == .leftMirrored ||
        self.imageOrientation == .right ||
        self.imageOrientation == .rightMirrored
#elseif os(macOS)
        return self.size.height > self.size.width
#endif
    }
    
}

extension PHAsset {
    var fileSizeInMB: Double {
        let resources = PHAssetResource.assetResources(for: self)
        guard let resource = resources.first else { return 0.0 }
        
        if let unsignedInt64 = resource.value(forKey: "fileSize") as? CLong {
            return Double(unsignedInt64) / (1024.0 * 1024.0)
        }
        
        return 0.0
    }
}


extension DetectedOrientation {
    func reversed(interactions: Int) -> DetectedOrientation {
        switch self {
        case .up:
            switch interactions {
            case 1: return .up
            case 2: return .rotatedLeft
            case 3: return .upsideDown
            case 4: return .rotatedRight
            default: return .up
            }
        case .rotatedRight:
            switch interactions {
            case 1: return .rotatedRight
            case 2: return .up
            case 3: return .rotatedLeft
            case 4: return .upsideDown
            default: return .up
            }
        case .upsideDown:
            switch interactions {
            case 1: return .upsideDown
            case 2: return .rotatedRight
            case 3: return .up
            case 4: return .rotatedLeft
            default: return .up
            }
        case .rotatedLeft:
            switch interactions {
            case 1: return .rotatedLeft
            case 2: return .upsideDown
            case 3: return .rotatedRight
            case 4: return .up
            default: return .up
            }
        }
    }
}


extension View {
    @ViewBuilder
    func isPresent(_ flag: Bool) -> some View {
        if flag {
            self
        } else {
            self.hidden()
        }
    }
    
    @ViewBuilder
    func minMacFrame(width: CGFloat, height: CGFloat) -> some View {
        #if os(macOS)
        self.frame(minWidth: width, minHeight: height)
        #else
        self
        #endif
    }
    
    @ViewBuilder
    func minNoMacFrame(width: CGFloat, height: CGFloat) -> some View {
        #if os(macOS)
        self
        #else
        self.frame(minWidth: width, minHeight: height)
        #endif
    }
}


#if os(iOS)
extension CGImagePropertyOrientation {
    /// Bridge from UIImage.Orientation to CGImagePropertyOrientation
    init(_ ui: UIImage.Orientation) {
        switch ui {
        case .up:             self = .up
        case .down:           self = .down
        case .left:           self = .left
        case .right:          self = .right
        case .upMirrored:     self = .upMirrored
        case .downMirrored:   self = .downMirrored
        case .leftMirrored:   self = .leftMirrored
        case .rightMirrored:  self = .rightMirrored
        @unknown default:     self = .up
        }
    }
}
#endif
