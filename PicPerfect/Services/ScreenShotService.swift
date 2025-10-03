//
//  ScreenShotService.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 10/2/25.
//

import SwiftUI
import Photos

class ScreenShotService {
    
    static func fetchScreenshotsBatch(limit: Int, offset: Int = 0) async -> [ImageInfo] {
        let screenshotsCollection = PHAssetCollection.fetchAssetCollections(
            with: .smartAlbum,
            subtype: .smartAlbumScreenshots,
            options: nil
        )
        
        guard let collection = screenshotsCollection.firstObject else {
            return []
        }
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let allScreenshots = PHAsset.fetchAssets(in: collection, options: fetchOptions)
        
        guard allScreenshots.count > 0 else { return [] }
        
        let start = offset
        let end = min(offset + limit, allScreenshots.count)
        
        guard start < end else { return [] }
        
        var infos: [ImageInfo] = []
        
        for index in start..<end {
            
            let asset = allScreenshots.object(at: index)
            if let image = await Service.requestImage(for: asset, size: CGSize(width: 300, height: 300)) {
                let info = ImageInfo(isIncorrect: false, image: image, asset: asset)
                
                infos.append(info)
            }
        }
        
        return infos
    }
}
