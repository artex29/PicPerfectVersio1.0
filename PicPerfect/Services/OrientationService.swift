//
//  OrientationService.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 8/16/25.
//

import PhotosUI
import SwiftUI
import Vision
import CoreML
import Playgrounds



class OrientationService {
    
    static func correctedOrientation(for image: ImageInfo) async -> ImageInfo {
        
        var resultedImage: ImageInfo = image
        
        let preprocessedImage = image.image.resized()
        
        if let faceImage = detectFace(in: resultedImage) {
           
            return faceImage
        }
        
        if let horizonImage = detectHorizon(in: resultedImage) {
            
            return horizonImage
        }
        
        print("🤖 No object or face detected — using Core ML")
        
        resultedImage.imageType = .unknown
        
        
        let configuration = MLModelConfiguration()
        
        guard let coreMLModel = try? PicPerfectOrientationClassifier(configuration: configuration),
              let visionModel = try? VNCoreMLModel(for: coreMLModel.model) else {
            print("❌ Could not load Core ML model")
            return resultedImage
        }
        
        //let orientation = await predictOrientation(with: visionModel, image: preprocessedImage)
        let result = await predictResults(with: visionModel, image: preprocessedImage)?.max(by: { $0.confidence < $1.confidence })
        print("Result: \(String(describing: result))")
        let orientation = result?.orientation ?? .up
        let finalImage = result?.image ?? preprocessedImage
        
        resultedImage.source = "coreML"
        resultedImage.orientation = orientation
        resultedImage.confidence = result?.confidence ?? 0.0
        resultedImage.isIncorrect = false
        
        switch orientation {
        case .rotatedLeft:
            resultedImage.image = rotate(image: finalImage, angle: .pi / 2)
            resultedImage.rotationAngle = 90.0
            return resultedImage
        case .rotatedRight:
            resultedImage.image = rotate(image: finalImage, angle: -.pi / 2)
            resultedImage.rotationAngle = -90.0
            return resultedImage
        case .upsideDown:
            resultedImage.image = rotate(image: finalImage, angle: .pi)
            resultedImage.rotationAngle = 180.0
            return resultedImage
        case .up:
            resultedImage.image = finalImage
            resultedImage.rotationAngle = 0.0
            return resultedImage
        }
    }
    
    private static func detectFace(in image: ImageInfo) -> ImageInfo? {
        guard let cgImage = image.image.cgImage else { return nil }

        var resultedImage: ImageInfo = image
        resultedImage.confidence = 1.0
        resultedImage.isIncorrect = false
        resultedImage.imageType = .face
        
        let request = VNDetectFaceLandmarksRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try? handler.perform([request])

        if let face = request.results?.first as? VNFaceObservation, let roll = face.roll?.doubleValue {
            let degrees = roll * 180 / .pi
            print("🧠 [Face] Roll: \(degrees)°")
            
            let tolerance = 0.2
            if abs(roll + .pi) < tolerance || abs(roll - .pi) < tolerance {
                
                resultedImage.image = rotate(image: image.image, angle: .pi)
                
                resultedImage.orientation = .upsideDown
                
                resultedImage.rotationAngle = 180.0
                
                return resultedImage
                
            } else if abs(roll - (.pi / 2)) < tolerance {
                resultedImage.image = rotate(image: image.image, angle: .pi / 2)
                
                resultedImage.orientation = .rotatedLeft
                
                resultedImage.rotationAngle = 90.0
                
                return resultedImage
            } else if abs(roll + (.pi / 2)) < tolerance {
                resultedImage.image = rotate(image: image.image, angle: -.pi / 2)
                
                resultedImage.orientation = .rotatedRight
                
                resultedImage.rotationAngle = -90.0
                
                return resultedImage
            } else {
                resultedImage.orientation = .up
                resultedImage.rotationAngle = 0.0
                return resultedImage
            }
        }

        return nil
    }
    
    private static func detectHorizon(in image: ImageInfo) -> ImageInfo? {
        guard let cgImage = image.image.cgImage else { return nil }
        
        var resultedImage: ImageInfo = image
        resultedImage.confidence = 1.0
        resultedImage.isIncorrect = false
        resultedImage.imageType = .horizon
        
        let request = VNDetectHorizonRequest()
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try? handler.perform([request])
        
        if let horizon = request.results?.first as? VNHorizonObservation {
            // print("🧠 Detected horizon: \(horizon)")
            
            let tolerance = 0.2
            let angle = horizon.angle
            
            print("🧠 [Horizon] Angle: \(angle) radians")
            
            if abs(Double(angle) - 1.0) < tolerance {
                resultedImage.image = rotate(image: image.image, angle: 0)
                resultedImage.rotationAngle = 0.0
                resultedImage.orientation = .up
                return resultedImage
            } else if abs(Double(angle) - 0.75) < tolerance {
                resultedImage.image = rotate(image: image.image, angle: .pi / 2)
                resultedImage.rotationAngle = 90.0
                resultedImage.orientation = .rotatedLeft
                return resultedImage
            } else if abs(Double(angle) - 0.5) < tolerance {
                resultedImage.image = rotate(image: image.image, angle: .pi)
                resultedImage.rotationAngle = 180.0
                resultedImage.orientation = .upsideDown
                return resultedImage
            } else if abs(Double(angle) - 0.25) < tolerance {
                resultedImage.image = rotate(image: image.image, angle: -.pi / 2)
                resultedImage.rotationAngle = -90.0
                resultedImage.orientation = .rotatedRight
                return resultedImage
            } else {
                return image
            }
            
        }
        
        return nil
    }
    
    private static func predictResults(with model: VNCoreMLModel, image: UIImage) async -> [PredictedResult]? {
        
        await withCheckedContinuation { continuation in
           
            var predictedResults: [PredictedResult] = []
            var predictedResult: PredictedResult = PredictedResult(image: image, orientation: .up, confidence: 0.0)
            
            
            let request = VNCoreMLRequest(model: model) { request, error in
                guard let results = request.results as? [VNClassificationObservation],
                      let top = results.first
                else {
                    print("❌ No results from Core ML model")
                    continuation.resume(returning: .none)
                    return
                }
                
                print("🔍 Core ML result: \(top.identifier) — confidence: \(top.confidence)")
                
                let label = top.identifier.replacingOccurrences(of: "_", with: "").lowercased()
                
                var orientation: DetectedOrientation = .up
                
                switch label {
                case "up":
                    orientation = .up
                case "rotatedleft":
                    orientation = .rotatedLeft
                case "rotatedright":
                    orientation = .rotatedRight
                case "upsidedown":
                    orientation = .upsideDown
                default:
                    orientation = .up
                }
                
                predictedResult.orientation = orientation
                predictedResult.confidence = top.confidence
                
                predictedResults.append(predictedResult)
                    
            }
            
            for orientation in DetectedOrientation.allCases {
                let rotatedImage = rotate(image: image, angle: 0, rotateTo: orientation)
                
                predictedResult = PredictedResult(image: rotatedImage, orientation: .up, confidence: 0.0)
                
                guard let cgImage = rotatedImage.cgImage else { continue }
                
                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                try? handler.perform([request])
            }
            
            if predictedResults.isEmpty {
                continuation.resume(returning: nil)
            } else {
                continuation.resume(returning: predictedResults)
            }
        }
    }
    
    private static func predictOrientation(with model: VNCoreMLModel, image: UIImage) async -> DetectedOrientation? {
        
        await withCheckedContinuation { continuation in
            
            
            var results: [DetectedOrientation: Float] = [:]
            var interactions = 0
            
            let request = VNCoreMLRequest(model: model) { request, error in
                guard
                    let observations = request.results as? [VNClassificationObservation],
                    let top = observations.first
                else {
                    continuation.resume(returning: nil)
                    return
                }
                
                print("🔍 Core ML result: \(top.identifier) — confidence: \(top.confidence)")
                
                let label = top.identifier.replacingOccurrences(of: "_", with: "").lowercased()
                
                var orientation: DetectedOrientation = .up
                let confidence:Float = top.confidence
                
                switch label {
                case "up":
                    orientation = .up
                case "rotatedleft":
                    orientation = .rotatedLeft
                case "rotatedright":
                    orientation = .rotatedRight
                case "upsidedown":
                    orientation = .upsideDown
                default:
                    orientation = .up
                }
                
                
                
                let reversedOrientation = orientation.reversed(interactions: interactions)
                
                print("🔄 Mapped orientation: \(orientation) -> \(reversedOrientation) after \(interactions) interactions")
                
                results[reversedOrientation] = results[reversedOrientation, default: 0.0] < confidence ? confidence : results[reversedOrientation, default: 0.0]
                
            }
            
            for orientation in DetectedOrientation.allCases {
                
                interactions += 1
                
                let rotatedImage = rotate(image: image, angle: 0, rotateTo: orientation)
                
                guard let cgImage = rotatedImage.cgImage else { continue }
                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                try? handler.perform([request])
            }
            
            continuation.resume(returning: results.max(by: { $0.value < $1.value })?.key)
        }
    }
    
    static func isImageIncorrectlyOriented(in image: UIImage) async -> Bool {
        guard let cgImage = image.cgImage else { return false }
        
        let faceRequest = VNDetectFaceLandmarksRequest()
        let faceHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try? faceHandler.perform([faceRequest])
        
        let preprocessedImage = image.resized()
        
        if let face = faceRequest.results?.first as? VNFaceObservation {
            if let roll = face.roll?.doubleValue {
                let degrees = roll * 180 / .pi
                print("🌀 Detected roll: \(roll) radians (\(degrees)°)")
                
                let tolerance = 0.2
                if abs(roll + .pi) < tolerance || abs(roll - .pi) < tolerance {
                  
                    return true
                } else if abs(roll - (.pi / 2)) < tolerance {

                    return true
                } else if abs(roll + (.pi / 2)) < tolerance {

                    return true
                } else {

                    return false
                }
            }
            
            return false
        }
        
        let textRequest = VNRecognizeTextRequest()
        let textHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try? textHandler.perform([textRequest])
        
        if let text = textRequest.results?.first as? VNRecognizedTextObservation {
            if text.topCandidates(1).isEmpty == false {
                print("📝 Detected text in image")
                return false
            }
            else {
                return true
            }
        }
        
        
        // 2. No hay rostro → usar Core ML
        print("🤖 No face detected — using Core ML")
        
        let configuration = MLModelConfiguration()
        guard let coreMLModel = try? PicPerfectOrientationClassifier(configuration: configuration),
              let visionModel = try? VNCoreMLModel(for: coreMLModel.model) else {
            print("❌ Could not load Core ML model")

            return false
        }
        
        let orientation = await predictOrientation(with: visionModel, image: preprocessedImage)
        
        switch orientation {
        case .rotatedLeft, .rotatedRight, .upsideDown:

            return true
        default:

            return false
        }
       
    }
    
    private static func rotate(image: UIImage, angle: CGFloat, rotateTo: DetectedOrientation? = nil) -> UIImage {
        
        var finalAngle: CGFloat = 0.0
        
        switch rotateTo {
        case .up:
            finalAngle = 0.0
        case .rotatedLeft:
            finalAngle = -.pi / 2
        case .rotatedRight:
            finalAngle = .pi / 2
        case .upsideDown:
            finalAngle = .pi
        case .none:
            finalAngle = angle
        }
        
        
        let renderer = UIGraphicsImageRenderer(size: image.size)
        return renderer.image { context in
            let ctx = context.cgContext
            ctx.translateBy(x: image.size.width / 2, y: image.size.height / 2)
            ctx.rotate(by: finalAngle)
            ctx.translateBy(x: -image.size.width / 2, y: -image.size.height / 2)
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
    }
}
