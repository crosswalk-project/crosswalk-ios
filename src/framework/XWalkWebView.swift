// Copyright (c) 2014 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import WebKit

public extension WKWebView {
    convenience init(frame: CGRect, configuration: WKWebViewConfiguration!, script: String?) {
        self.init(frame: frame, configuration: configuration)

        let bundle = NSBundle(forClass: XWalkExtension.self)
        if script != nil {
            injectScript(script!)
        } else if let path = bundle.pathForResource("extension_api", ofType: "js") {
            if let file = NSFileHandle(forReadingAtPath: path) {
                if let api = NSString(data: file.readDataToEndOfFile(), encoding: NSUTF8StringEncoding) {
                    injectScript(api)
                }
            }
        }
    }

    public func loadExtension(name: String) -> Bool {
        if let ext = XWalkExtensionManager.defaultManager().createExtension(name) {
            ext.webView = self

            // Register message handler
            let id = name.stringByReplacingOccurrencesOfString(".", withString: "")
            configuration.userContentController.addScriptMessageHandler(ext, name: id)

            // Inject JavaScript API
            let code = join("\n", [
                "(function() {",
                "   'use strict';",
                "    var exports = new Extension('\(name)', '\(id)');",
                "    \(ext.jsAPIStub)",
                "    \(name) = exports;",
                "})();"])
            injectScript(code)
            return true
        }
        return false
    }

    public func loadExtensions(names: [String]) {
        for name in names {
            loadExtension(name)
        }
    }

    public func unloadExtension(name: String) {
        let id = name.stringByReplacingOccurrencesOfString(".", withString: "")
        configuration.userContentController.removeScriptMessageHandlerForName(id)
    }

    public func injectScript(code: String) {
        let script = WKUserScript(
            source: code,
            injectionTime: WKUserScriptInjectionTime.AtDocumentStart,
            forMainFrameOnly: false)
        configuration.userContentController.addUserScript(script)
    }
}
