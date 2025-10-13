//
//  AppleIntelligence.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 9/17/25.
//

import FoundationModels
import SwiftUI
import Playgrounds

@available(iOS 26.0, macOS 26.0, watchOS 26.0, visionOS 26.0, *)

@Generable
struct OrientationPrediction {
    @Guide(
        description: "analyze the image and predict its correct orientation"
    )
    
    var results: result
    var imageDescription: String
}

@available(iOS 26.0, macOS 26.0, watchOS 26.0, visionOS 26.0, *)
@Generable
struct result  {
    var orientation: String
    var confidence: Float
    
}

#Playground {
   
    if #available(iOS 26.0, macOS 26.0, watchOS 26.0, visionOS 26.0, *) {
        
        let uiImage = PPImage(named: "exampleImage2")!
        
        let prompt = """
        Analyze the image \(uiImage) and predict its correct orientation.
        Possible results are:
        - **up**: the photo is already correctly oriented
        - **rotatedRight**: the photo is rotated 90° clockwise
        - **upsideDown**: the photo is rotated 180°
        - **rotatedLeft**: the photo is rotated 90° counterclockwise

        Along with the orientation, return a confidence score between 0.0 and 1.0 that indicates how certain the model is about its prediction, and a short description of the what you see on the image no more thatn 5 words.
        """
        
        let session = LanguageModelSession()
        
        let response = try await session.respond(
            to: prompt,
            generating: OrientationPrediction.self
        )
        
        print(response.content)
    }
    
   
}
