// Copyright (c) 2014 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import WebKit

public extension WKWebView {
    convenience init(frame: CGRect, configuration: WKWebViewConfiguration!, extendable: Bool) {
        self.init(frame: frame, configuration: configuration)
        
    }
    public func loadExtension(bundleName: String) {
        let bundlePath = NSBundle.mainBundle().pathForResource(bundleName,
            ofType: "framework", inDirectory:"Frameworks")
        if bundlePath == nil {
            println("Failed to locate extension bundle:\(bundleName)")
            return
        }
        var bundle : NSBundle = NSBundle(path:bundlePath!)!
        var error : NSErrorPointer = nil;
        if !bundle.loadAndReturnError(error) {
            println("Failed to load bundle:\(bundlePath) with error:\(error)")
            return
        }
        
        var configPath = bundle.pathForResource("manifest", ofType: "plist")
        if configPath == nil {
            println("Failed to find manifest.plist")
            return
        }
        
        let config = NSDictionary(contentsOfFile: configPath!)
        typealias ExtensionFactory = ObjectFactory<XWalkExtension>
        let className = config!["class"] as String
        if let e: XWalkExtension = ExtensionFactory.createInstance(className: "\(bundleName).\(className)") {
            e.name = config!["name"] as String
            
            let jsApiFileName = (config!["jsapi"] as String).componentsSeparatedByString(".")
            if let jsPath = bundle.pathForResource(jsApiFileName[0], ofType: jsApiFileName[1]) {
                let jsData = NSFileHandle(forReadingAtPath: jsPath)!.readDataToEndOfFile()
                e.jsAPI = NSString(data: jsData, encoding: NSUTF8StringEncoding)!
            }
            e.injectJSCodes(self.configuration.userContentController)
        }
    }
    public func unloadExtension(name: String) {
        self.configuration.userContentController.removeScriptMessageHandlerForName(name)
    }
    public func loadExtensions(names: [String]) {
        for name in names {
            loadExtension(name)
        }
    }
}
