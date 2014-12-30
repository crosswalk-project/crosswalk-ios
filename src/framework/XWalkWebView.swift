// Copyright (c) 2014 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import WebKit

public extension WKWebView {
    public func loadExtension(name: String, namespace: String? = nil, parameter: AnyObject? = nil) -> Bool {
        struct key {
            static let ptr:[CChar] = [0x43, 0x72, 0x6f, 0x73, 0x73, 0x77, 0x61, 0x6c, 0x6b, 0]
        }
        if objc_getAssociatedObject(self, key.ptr) == nil {
            prepareForExtension()
            objc_setAssociatedObject(self, key.ptr, NSNull(), objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
        }

        if let ext: AnyObject = XWalkExtensionFactory.createExtension(name, parameter: parameter) {
            let channel = XWalkChannel(webView: self)
            channel.bind(ext, namespace: namespace ?? name)
            return true
        }
        return false
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

    private func prepareForExtension() {
        let bundle = NSBundle(forClass: XWalkChannel.self)
        if let path = bundle.pathForResource("extension_api", ofType: "js") {
            if let code = NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding, error: nil) {
                injectScript(code)
            } else {
                NSException.raise("EncodingError", format: "'%@.js' should be UTF-8 encoding.", arguments: getVaList([path]))
            }
        }
    }
}
