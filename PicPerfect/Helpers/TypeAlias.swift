//
//  TypeAlias.swift
//  PicPerfect
//
//  Created by ANGEL RAMIREZ on 10/10/25.
//



#if os(iOS)
import UIKit
typealias PPImage = UIImage
#elseif os(macOS)
import AppKit
typealias PPImage = NSImage
#endif
