//
//  PhotoSummary.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 10/2/25.
//

import Foundation
import CoreLocation
import Photos
import ImageIO
import CoreGraphics

struct PhotoSummary: Hashable {
    let filename: String?
    let creationDate: Date?
    let modificationDate: Date?
    let location: CLLocation?
    let pixelSize: CGSize
    let exif: [String: Any]?

    static func == (lhs: PhotoSummary, rhs: PhotoSummary) -> Bool {
        return lhs.filename == rhs.filename &&
               lhs.creationDate == rhs.creationDate &&
               lhs.modificationDate == rhs.modificationDate &&
               lhs.pixelSize == rhs.pixelSize &&
               lhs.location?.coordinate.latitude == rhs.location?.coordinate.latitude &&
               lhs.location?.coordinate.longitude == rhs.location?.coordinate.longitude
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(filename)
        hasher.combine(creationDate)
        hasher.combine(modificationDate)
        hasher.combine(pixelSize.width)
        hasher.combine(pixelSize.height)
        if let loc = location {
            hasher.combine(loc.coordinate.latitude)
            hasher.combine(loc.coordinate.longitude)
        }
    }
}

class PhotoSummaryService {
    
    static func getPhotoSummary(for asset: PHAsset, completion: @escaping (PhotoSummary?) -> Void) {
        let filename = PHAssetResource.assetResources(for: asset).first?.originalFilename
        let pixelSize = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
        let creation = asset.creationDate
        let modification = asset.modificationDate
        // request image data for EXIF/GPS
        PHImageManager.default().requestImageDataAndOrientation(for: asset, options: nil) { data, _, _, _ in
            var exif: [String: Any]? = nil
            var extractedLocation: CLLocation? = nil
            if let data = data, let metadata = self.metadataFromImageData(data) {
                exif = metadata[kCGImagePropertyExifDictionary as String] as? [String: Any]
                extractedLocation = gpsLocation(from: metadata)
            }
            let summary = PhotoSummary(
                filename: filename,
                creationDate: creation,
                modificationDate: modification,
                location: extractedLocation ?? asset.location,
                pixelSize: pixelSize,
                exif: exif
            )
            completion(summary)
        }
    }
    
    private static func metadataFromImageData(_ data: Data) -> [String: Any]? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        guard let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] else { return nil }
        return props
    }
    
    private static func gpsLocation(from metadata: [String: Any]) -> CLLocation? {
        if let gps = metadata[kCGImagePropertyGPSDictionary as String] as? [String: Any] {
            if let lat = gps[kCGImagePropertyGPSLatitude as String] as? Double,
               let latRef = gps[kCGImagePropertyGPSLatitudeRef as String] as? String,
               let lon = gps[kCGImagePropertyGPSLongitude as String] as? Double,
               let lonRef = gps[kCGImagePropertyGPSLongitudeRef as String] as? String {
                
                let latitude = (latRef == "S") ? -lat : lat
                let longitude = (lonRef == "W") ? -lon : lon
                let altitude = gps[kCGImagePropertyGPSAltitude as String] as? Double ?? 0.0
                return CLLocation(coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                                  altitude: altitude,
                                  horizontalAccuracy: 0,
                                  verticalAccuracy: 0,
                                  timestamp: Date())
            }
        }
        return nil
    }
}

