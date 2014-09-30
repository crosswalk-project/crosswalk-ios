//
//  XWalkExtensionManager.swift
//  CrosswalkiOS
//
//  Created by Jonathan Dong on 14/9/24.
//  Copyright (c) 2014年 Crosswalk. All rights reserved.
//

import Foundation
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

        var plistPath = bundle.pathForResource("manifest", ofType: "plist")
        if plistPath == nil {
            println("Failed to find manifest.plist")
            return
        }

        let config = NSDictionary(contentsOfFile: plistPath!)
        typealias ExtensionFactory = ObjectFactory<XWalkExtension>
        var className = config["class"] as String
        if let e: XWalkExtension = ExtensionFactory.createInstance(className: "\(bundleName).\(className)") {
            e.name = config["name"] as String
            e.delegate = self

            let jsApiFileName = split(config["jsapi"] as String, { (c:Character) -> Bool in
                return c == "."
            })
            if let jsPath = bundle.pathForResource(jsApiFileName[0], ofType: jsApiFileName[1]) {
                let jsData = NSFileHandle(forReadingAtPath: jsPath).readDataToEndOfFile()
                e.jsAPI = NSString(data: jsData, encoding: NSUTF8StringEncoding)

                let userScript = WKUserScript(source: e.jsAPI, injectionTime:
                    WKUserScriptInjectionTime.AtDocumentStart, forMainFrameOnly: false)
                contentController?.addUserScript(userScript)
            }
            registerExtension(e);
        }
    }
}
