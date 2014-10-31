// Copyright (c) 2014 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import WebKit

public extension WKWebView {
    convenience init(frame: CGRect, configuration: WKWebViewConfiguration!, extendable: Bool) {
        self.init(frame: frame, configuration: configuration)
        
    }

    public func loadExtension(bundleName: String, className: String?) {
        let path = NSBundle.mainBundle().pathForResource(bundleName,
            ofType: "framework", inDirectory:"Frameworks")
        if path == nil {
            println("Failed to locate extension bundle:\(bundleName)")
            return
        }

        if let bundle = NSBundle(path:path!) {
            var error : NSErrorPointer = nil;
            if !bundle.loadAndReturnError(error) {
                println("Failed to load bundle:\(path!) with error:\(error)")
                return
            }

            let name = bundleName + "." + (className ?? NSStringFromClass(bundle.principalClass) ?? bundleName)
            typealias ExtensionFactory = ObjectFactory<XWalkExtension>
            var ext = ExtensionFactory.createInstance(className: "\(name)", initializer: "initWithWebView:", argument: self)
            if ext == nil {
                println("Can't create extension")
            }
        } else {
            println("Bundle not found: \(path!)")
        }
    }

    public func unloadExtension(name: String) {
        self.configuration.userContentController.removeScriptMessageHandlerForName(name)
    }

    public func loadExtensions(names: [String]) {
        for name in names {
            loadExtension(name, className: nil)
        }
    }
}
