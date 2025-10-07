//
//  DeviceHelper.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 10/7/25.
//

enum  DeviceType {
    case iPhone
    case iPad
    case mac
    case watch
}

import Foundation
import SwiftUI

class DeviceHelper {
    static var type:DeviceType {
        #if os(iOS)
        return UIDevice.current.userInterfaceIdiom == .phone ? .iPhone : .iPad
        #elseif os(watchOS)
        return .watch
        #else
        return .mac
        #endif
    }
}
