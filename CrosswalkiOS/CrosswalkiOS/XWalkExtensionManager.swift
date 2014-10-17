// Copyright (c) 2014 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation
import SwiftyJSON
import WebKit

protocol XWalkExtensionManagerDelegate {
    func onEvaluateJavascript(jsCode: String)
}

class XWalkExtensionManager: NSObject, XWalkExtensionDelegate {
    var extensions = Dictionary<String, XWalkExtension>()
    var delegate: XWalkExtensionManagerDelegate?
    weak var contentController: WKUserContentController? {
        didSet {
            LoadDefaultExtensionScript()
        }
    }

    func registerExtension(e: XWalkExtension) {
        if let existingExtension = extensions[e.name] {
            println("\(e.name) is already registered!")
        } else {
            e.delegate = self
            e.injectJSCodes(contentController!)
            extensions[e.name] = e
        }
    }

    func unregisterExtension(name: String) {
        if let existingExtension = extensions[name] {
            extensions[name] = nil
            contentController?.removeScriptMessageHandlerForName(name)
        }
    }

    func loadExtensionsByBundleNames(names: [String]) {
        for name in names {
            loadExtensionByBundleName(name)
        }
    }

    func onEvaluateJavascript(e: XWalkExtension, jsCode: String) {
        delegate?.onEvaluateJavascript(jsCode);
    }

    func LoadDefaultExtensionScript() {
        let path = NSBundle.mainBundle().pathForResource("CrosswalkiOS",
            ofType: "framework", inDirectory:"Frameworks")
        if path == nil {
            println("Failed to locate bundle: CrosswalkiOS")
            return
        }
        var bundle = NSBundle(path: path!)
        if let scriptPath = bundle.pathForResource("device_capabilities_api", ofType: "js") {
            let jsData = NSFileHandle(forReadingAtPath: scriptPath).readDataToEndOfFile()
            let e: XWalkExtension = DeviceCapabilitesExtension()
            e.name = "xwalk.experimental.system"
            e.jsAPI = NSString(data: jsData, encoding: NSUTF8StringEncoding)
            registerExtension(e)
        }
    }

    func loadExtensionByBundleName(bundleName: String) {
        let bundlePath = NSBundle.mainBundle().pathForResource(bundleName,
            ofType: "framework", inDirectory:"Frameworks")
        if bundlePath == nil {
            println("Failed to locate extension bundle:\(bundleName)")
            return
        }
        var bundle = NSBundle(path:bundlePath!)
        var error : NSErrorPointer = nil;
        if !bundle.loadAndReturnError(error) {
            println("Failed to load bundle:\(bundlePath) with error:\(error)")
            return
        }

        var configPath = bundle.pathForResource("manifest", ofType: "json")
        if configPath == nil {
            println("Failed to find manifest.json")
            return
        }

        let config = JSON(data: NSFileHandle(forReadingAtPath: configPath!).readDataToEndOfFile())
        typealias ExtensionFactory = ObjectFactory<XWalkExtension>
        let className = config["class"].stringValue
        if let e: XWalkExtension = ExtensionFactory.createInstance(className: "\(bundleName).\(className)") {
            e.name = config["name"].stringValue

            let jsApiFileName = config["jsapi"].stringValue.componentsSeparatedByString(".")
            if let jsPath = bundle.pathForResource(jsApiFileName[0], ofType: jsApiFileName[1]) {
                let jsData = NSFileHandle(forReadingAtPath: jsPath).readDataToEndOfFile()
                e.jsAPI = NSString(data: jsData, encoding: NSUTF8StringEncoding)
            }
            registerExtension(e)
        }
    }
}
