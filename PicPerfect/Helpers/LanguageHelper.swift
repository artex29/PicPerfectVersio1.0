//
//  LanguageHelper.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 10/23/25.
//

import SwiftUI

enum Languages: CaseIterable, Hashable {
    case english
    case spanish
    
}

class LanguageHelper {
    
    static func language() -> Languages {
        let locale = Locale.current.language.languageCode?.identifier
        
        if locale == "en" {
            return .english
        } else {
            return .spanish
        }

    }
}
