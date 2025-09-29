//
//  Extensions.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 9/5/25.
//

import UIKit
import SwiftUI

extension UIImage {
    func fixedOrientation() -> UIImage {
        guard let cgImage = self.cgImage else { return self }

        if self.imageOrientation == .up {
            return self
        }

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
              let context = CGContext(data: nil,
                                      width: Int(size.width),
                                      height: Int(size.height),
                                      bitsPerComponent: cgImage.bitsPerComponent,
                                      bytesPerRow: 0,
                                      space: colorSpace,
                                      bitmapInfo: cgImage.bitmapInfo.rawValue) else {
            return self
        }

        context.concatenate(transform)

        let drawRect: CGRect
        if self.isPortrait {
            drawRect = CGRect(x: 0, y: 0, width: size.height, height: size.width)
        } else {
            drawRect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        }

        context.draw(cgImage, in: drawRect)

        guard let newCGImage = context.makeImage() else { return self }

        return UIImage(cgImage: newCGImage)
    }
    
    func resized(maxDimension: CGFloat = 1024) -> UIImage {
        let originalSize = self.size
        let scale = min(maxDimension / originalSize.width, maxDimension / originalSize.height, 1.0)
        let newSize = CGSize(width: originalSize.width * scale, height: originalSize.height * scale)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    
    var isPortrait: Bool {
        return self.imageOrientation == .left || self.imageOrientation  == .leftMirrored || self.imageOrientation  == .right || self.imageOrientation  == .rightMirrored
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
}

extension Image {
    func toUIImage() -> UIImage {
        let controller = UIHostingController(rootView: self)
        let view = controller.view
        
        let targetSize = controller.view.intrinsicContentSize
        view?.bounds = CGRect(origin: .zero, size: targetSize)
        view?.backgroundColor = .clear
        
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            view?.drawHierarchy(in: view!.bounds, afterScreenUpdates: true)
        }
    }
}
