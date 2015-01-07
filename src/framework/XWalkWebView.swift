// Copyright (c) 2014 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import WebKit

public extension WKWebView {
    private struct key {
        static let thread = UnsafePointer<Void>(bitPattern: Selector("extensionThread").hashValue)
    }
    public var extensionThread: NSThread {
        get {
            if objc_getAssociatedObject(self, key.thread) == nil {
                prepareForExtension()
                let thread = XWalkThread()
                objc_setAssociatedObject(self, key.thread, thread, UInt(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
                return thread
            }
            return objc_getAssociatedObject(self, key.thread) as NSThread
        }
        set(thread) {
            if objc_getAssociatedObject(self, key.thread) == nil {
                prepareForExtension()
            }
            objc_setAssociatedObject(self, key.thread, thread, UInt(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
        }
    }

    public func loadExtension(object: AnyObject, namespace: String, thread: NSThread? = nil) {
        let channel = XWalkChannel(webView: self)
        channel.bind(object, namespace: namespace, thread: thread)
    }

    internal func injectScript(code: String) -> WKUserScript {
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
        return script
    }

    private func prepareForExtension() {
        let bundle = NSBundle(forClass: XWalkChannel.self)
        if let path = bundle.pathForResource("crosswalk", ofType: "js") {
            if let code = NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding, error: nil) {
                injectScript(code)
            } else {
                NSException.raise("EncodingError", format: "'%@.js' should be UTF-8 encoding.", arguments: getVaList([path]))
            }
        }
    }
}

extension WKUserContentController {
    func removeUserScript(script: WKUserScript) {
        let scripts = userScripts
        removeAllUserScripts()
        for i in scripts {
            if i !== script {
                addUserScript(i as WKUserScript)
            }
        }
    }
}
