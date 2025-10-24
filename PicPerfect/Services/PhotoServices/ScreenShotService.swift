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
        // Cargar registros previos del módulo screenshots
        //let analyzedRecords = await PhotoAnalysisCloudCache.loadRecords(for: .screenshots)
        
        // Fetch del smart album de screenshots
        let screenshotsCollection = PHAssetCollection.fetchAssetCollections(
            with: .smartAlbum,
            subtype: .smartAlbumScreenshots,
            options: nil
        )
        
        guard let collection = screenshotsCollection.firstObject else { return [] }
        
        let fetchOptions = PHFetchOptions()
        // 🔄 Ahora ordenamos de más viejas a más nuevas
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        
        let allScreenshots = PHAsset.fetchAssets(in: collection, options: fetchOptions)
        guard allScreenshots.count > 0 else { return [] }
        
        // Filtramos las que NO estén analizadas
        let analyzedIds = await PhotoAnalysisCloudCache.loadRecords(for: .screenshots)
            .map { $0.id }

        let unprocessed = (0..<allScreenshots.count)
            .map { allScreenshots.object(at: $0) }
            .filter { !analyzedIds.contains($0.localIdentifier) }
        
        // Aplicamos offset + limit
        let start = offset
        let end = min(offset + limit, unprocessed.count)
        guard start < end else { return [] }
        
        var infos: [ImageInfo] = []
        
        for index in start..<end {
            let asset = unprocessed[index]
            if let image = await Service.requestImage(for: asset, size: CGSize(width: 256, height: 256)) {
                let info = ImageInfo(
                    isIncorrect: false,
                    image: image,
                    asset: asset,
                    fileSizeInMB: asset.fileSizeInMB
                )
                infos.append(info)
            }
        }
        
        return infos
    }
}
