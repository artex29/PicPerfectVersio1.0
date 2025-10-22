//
//  ContentModel.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 9/18/25.
//

import Foundation
import Photos
import SwiftUI

@Observable
class ContentModel {
  
    var processedPhotos: [PPImage] = []
    var showHistoryView: Bool = false
    
    init() {
        Task {
            await loadProcessedPhotos()
        }
        
//        PhotoAnalysisCloudCache.clearProcessedPhotos()
    }
    
    func loadProcessedPhotos() async {
        
        processedPhotos.removeAll()
        
        let ids = PhotoAnalysisCloudCache.retrieveProcessedPhotos()
        
        PhotoLibraryScanner.shared.fetchProcessedPhotos(with: ids) { images in
            self.processedPhotos = images.prefix(10).reversed()
            
        }
    }
}
