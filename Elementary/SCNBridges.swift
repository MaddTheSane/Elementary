//
//  SCNBridges.swift
//  Elementary
//
//  Created by C.W. Betts on 9/17/20.
//  Copyright © 2020 Supinfo. All rights reserved.
//

#if os(macOS)
import Cocoa

typealias SCNColor = NSColor
typealias SCNImage = NSImage
#else
import UIKit

typealias SCNColor = UIColor
typealias SCNImage = UIImage
#endif
