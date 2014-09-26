//
//  XWalkExtensionManager.swift
//  CrosswalkiOS
//
//  Created by Jonathan Dong on 14/9/24.
//  Copyright (c) 2014年 Crosswalk. All rights reserved.
//

import Foundation
import WebKit

class XWalkExtensionManager :NSObject, WKScriptMessageHandler {
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

    func loadExtensions(controller: WKUserContentController) {
        controller.addScriptMessageHandler(self, name: "xwalk-extension")
        // TODO:(jondong) loading extension here

        for (_, e) in extensions {
            let userScript = WKUserScript(source: e.jsAPI, injectionTime: WKUserScriptInjectionTime.AtDocumentStart, forMainFrameOnly: true)
            controller.addUserScript(userScript)
        }
    }

    func postMessage(e: XWalkExtension, instanceID: Int, message: String) {
        // TODO:(jondong)
    }

    func broadcastMessage(e: XWalkExtension, message: String) {
        // TODO:(jondong)
    }

    func userContentController(userContentController: WKUserContentController!, didReceiveScriptMessage message: WKScriptMessage!) {
        println("script message received: \(message.body)")
    }
}