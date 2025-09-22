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
  
    var processedPhotos: [UIImage] = []
    
    init() {
        loadProcessedPhotos()
    }
    
    func loadProcessedPhotos() {
        let ids = PhotoAnalysisCloudCache.retrieveProcessedPhotos()
        
        PhotoLibraryScanner.shared.fetchProcessedPhotos(with: ids) { images in
            self.processedPhotos = images
        }
    }
}
