//
//  DuplicateGroup.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 9/22/25.
//


import Photos
import Vision
import UIKit

struct DuplicateGroup {
    let assets: [PHAsset]
    let distance: Float
}

enum DuplicateServiceError: Error {
    case imageRequestFailed
    case featurePrintFailed
}

/// Service para detectar duplicados en la librería de fotos
final class DuplicateService {
    
    /// Genera un feature print (embedding) de Vision para comparar imágenes
    private static func featurePrint(for image: UIImage) throws -> VNFeaturePrintObservation {
        guard let cgImage = image.cgImage else {
            throw DuplicateServiceError.imageRequestFailed
        }
        let request = VNGenerateImageFeaturePrintRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])
        guard let obs = request.results?.first as? VNFeaturePrintObservation else {
            throw DuplicateServiceError.featurePrintFailed
        }
        return obs
    }
    
    /// Detecta grupos de duplicados en una colección de PHAsset
    static func detectDuplicates(assets: [PHAsset], threshold: Float = 0.5, limit: Int = 100) async throws -> [DuplicateGroup] {
        var groups: [DuplicateGroup] = []
        var processed: Set<Int> = []
        
        // Generar feature prints para cada asset
        var featurePrints: [VNFeaturePrintObservation] = []
        for (index, asset) in assets.enumerated() {
            
            guard index < limit else { break }
            
            if let uiImage = await Service.requestImage(for: asset, size: CGSize(width: 256, height: 256)) {
                let obs = try featurePrint(for: uiImage)
                featurePrints.append(obs)
            } else {
                featurePrints.append(VNFeaturePrintObservation()) // marcador vacío
            }
        }
        
        // Comparar assets entre sí
        for i in 0..<assets.count {
            
            guard i < limit else { break }
            
            guard !processed.contains(i) else { continue }
            
            var group: [PHAsset] = [assets[i]]
            processed.insert(i)
            
            for j in (i+1)..<assets.count {
                guard !processed.contains(j) else { continue }
                
                var distance: Float = 1.0
                if featurePrints.indices.contains(i), featurePrints.indices.contains(j) {
                    try featurePrints[i].computeDistance(&distance, to: featurePrints[j])
                }
                
                if distance < threshold {
                    group.append(assets[j])
                    processed.insert(j)
                }
            }
            
            if group.count > 1 {
                groups.append(DuplicateGroup(assets: group, distance: 0))
            }
        }
        
        return groups
    }
}
