// Copyright (c) 2014 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import WebKit

public extension WKWebView {
    public func loadExtension(name: String, namespace: String? = nil, parameter: AnyObject? = nil) -> Bool {
        if let ext = XWalkExtensionFactory.singleton.createExtension(name, parameter: parameter) {
            ext.attach(self, namespace: namespace)
            return true
        }
        return false
    }

    private class var jsAPI: String {
        let bundle = NSBundle(forClass: XWalkExtension.self)
        var code : String? = nil
        if let path = bundle.pathForResource("extension_api", ofType: "js") {
            if let file = NSFileHandle(forReadingAtPath: path) {
                code = NSString(data: file.readDataToEndOfFile(), encoding: NSUTF8StringEncoding)
            }
        }
        return code ?? ""
    }

    internal func MakeExtensible(script: String? = nil) {
        struct key {
            static let ptr:[CChar] = [0x43, 0x72, 0x6f, 0x73, 0x73, 0x77, 0x61, 0x6c, 0x6b, 0]
        }
        if objc_getAssociatedObject(self, key.ptr) == nil {
            injectScript(script ?? WKWebView.jsAPI)
            objc_setAssociatedObject(self, key.ptr, NSNull(), objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
        }
    }

    internal func injectScript(code: String) {
        let script = WKUserScript(
            source: code,
            injectionTime: WKUserScriptInjectionTime.AtDocumentStart,
            forMainFrameOnly: false)
        configuration.userContentController.addUserScript(script)
        if self.URL != nil {
            evaluateJavaScript(code, completionHandler: { (obj, err)->Void in
                if err != nil {
                    println("ERROR: Failed to inject JavaScript API.\n\(err)")
                }
            })
        }
    }
}
