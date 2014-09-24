//
//  XWalkExtensionManager.swift
//  CrosswalkiOS
//
//  Created by Jonathan Dong on 14/9/24.
//  Copyright (c) 2014年 Crosswalk. All rights reserved.
//

import Foundation

class XWalkExtensionManager {
    var extensions = Dictionary<String, XWalkExtension>()

    func registerExtension(e: XWalkExtension) {
        if let existingExtension = extensions[e.name] {
            NSLog("\(e.name) is already registered!")
        } else {
            extensions[e.name] = e
        }
    }

    func unregisterExtension(name: String) {
        if let existingExtension = extensions[name] {
            extensions[name] = nil
        }
    }

    func loadExtensions() {
        // TODO:(jondong)
    }

    func postMessage(e: XWalkExtension, instanceID: Int, message: String) {
        // TODO:(jondong)
    }

    func broadcastMessage(e: XWalkExtension, message: String) {
        // TODO:(jondong)
    }
}