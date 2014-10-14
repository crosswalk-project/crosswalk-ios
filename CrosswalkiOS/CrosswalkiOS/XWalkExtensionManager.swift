// Copyright (c) 2014 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation
import SwiftyJSON
import WebKit

protocol XWalkExtensionManagerDelegate {
    func onPostMessageToJS(message: String)
}

class XWalkExtensionManager: NSObject, WKScriptMessageHandler, XWalkExtensionDelegate {
    var extensions = Dictionary<String, XWalkExtension>()
    var delegate: XWalkExtensionManagerDelegate?
    weak var contentController: WKUserContentController? {
        didSet {
            contentController?.addScriptMessageHandler(self, name: "xwalk")
            LoadDefaultExtensionScript()
        }
    }

    func registerExtension(e: XWalkExtension) {
        if let existingExtension = extensions[e.name] {
            println("\(e.name) is already registered!")
        } else {
            extensions[e.name] = e
        }
    }

    func unregisterExtension(name: String) {
        if let existingExtension = extensions[name] {
            extensions[name] = nil
        }
    }

    func loadExtensionsByBundleNames(names: [String]) {
        for name in names {
            loadExtensionByBundleName(name)
        }
    }

    func onPostMessageToJS(e: XWalkExtension, message: String) {
        delegate?.onPostMessageToJS(message)
    }

    func onBroadcastMessageToJS(e: XWalkExtension, message: String) {
        // (TODO) jondong
    }

    func userContentController(userContentController: WKUserContentController!,
        didReceiveScriptMessage message: WKScriptMessage!) {
        var msg: String = message.body as String
        for (_, e) in extensions {
            e.onMessage(msg)
        }
    }

    func LoadDefaultExtensionScript() {
        let path = NSBundle.mainBundle().pathForResource("CrosswalkiOS",
            ofType: "framework", inDirectory:"Frameworks")
        if path == nil {
            println("Failed to locate bundle: CrosswalkiOS")
            return
        }

        var bundle = NSBundle(path: path!)
        if let scriptPath = bundle.pathForResource("extension", ofType: "js") {
            let jsData = NSFileHandle(forReadingAtPath: scriptPath).readDataToEndOfFile()
            let jsContent = NSString(data: jsData, encoding: NSUTF8StringEncoding)
            let userScript = WKUserScript(source: jsContent,
                injectionTime: WKUserScriptInjectionTime.AtDocumentStart, forMainFrameOnly: false)
            contentController?.addUserScript(userScript)
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
        let className = config["class"].string!
        if let e: XWalkExtension = ExtensionFactory.createInstance(className: "\(bundleName).\(className)") {
            e.name = config["name"].string!
            e.delegate = self

            let jsApiFileName = split(config["jsapi"].string!, { (c:Character) -> Bool in
                return c == "."
            })
            if let jsPath = bundle.pathForResource(jsApiFileName[0], ofType: jsApiFileName[1]) {
                let jsData = NSFileHandle(forReadingAtPath: jsPath).readDataToEndOfFile()
                e.jsAPI = NSString(data: jsData, encoding: NSUTF8StringEncoding)
                injectJSCodes(e.jsAPI, extensionName: e.name)
            }
            registerExtension(e);
        }
    }

    func injectJSCodes(jsCodes: String, extensionName: String) {
        let codesToInject = "var \(extensionName); (function() { var exports = {}; (function() {'use strict'; \(jsCodes)})(); \(extensionName) = exports; })();";
        let userScript = WKUserScript(source: codesToInject, injectionTime:
            WKUserScriptInjectionTime.AtDocumentStart, forMainFrameOnly: false)
        contentController?.addUserScript(userScript)
    }
}
