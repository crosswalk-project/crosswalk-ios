// Copyright (c) 2014 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import WebKit

public extension WKWebView {
    private struct key {
        static let thread = UnsafePointer<Void>(bitPattern: Selector("extensionThread").hashValue)
        static let httpd = UnsafePointer<Void>(bitPattern: Selector("extensionHTTPD").hashValue)
    }
    public var extensionThread: NSThread {
        get {
            if objc_getAssociatedObject(self, key.thread) == nil {
                prepareForExtension()
                let thread = XWalkThread()
                objc_setAssociatedObject(self, key.thread, thread, UInt(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
                return thread
            }
            return objc_getAssociatedObject(self, key.thread) as! NSThread
        }
        set(thread) {
            if objc_getAssociatedObject(self, key.thread) == nil {
                prepareForExtension()
            }
            objc_setAssociatedObject(self, key.thread, thread, UInt(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
        }
    }

    public func loadExtension(object: AnyObject, namespace: String, thread: NSThread? = nil) {
        if !extensionThread.executing && thread == nil {
            extensionThread.start()
        }
        let channel = XWalkChannel(webView: self)
        channel.bind(object, namespace: namespace, thread: thread ?? extensionThread)
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
                injectScript(code as String)
            } else {
                NSException.raise("EncodingError", format: "'%@.js' should be UTF-8 encoding.", arguments: getVaList([path]))
            }
        }
    }

    // WKWebView can't load file URL on device. We have to start an embedded http server for proxy.
    // Upstream WebKit has solved this issue. This function should be removed once WKWebKit adopts the fix.
    // See: https://bugs.webkit.org/show_bug.cgi?id=137153
    public func loadFileURL(URL: NSURL, allowingReadAccessToURL readAccessURL: NSURL) -> WKNavigation? {
        if (!URL.fileURL || !readAccessURL.fileURL) {
            let url = URL.fileURL ? readAccessURL : URL
            NSException.raise(NSInvalidArgumentException, format: "%@ is not a file URL", arguments: getVaList([url]))
        }

        let fileManager = NSFileManager.defaultManager()
        var relationship: NSURLRelationship = NSURLRelationship.Other
        var isDirectory: ObjCBool = false
        if (!fileManager.fileExistsAtPath(readAccessURL.path!, isDirectory: &isDirectory) || !isDirectory || !fileManager.getRelationship(&relationship, ofDirectoryAtURL: readAccessURL, toItemAtURL: URL, error: nil) || relationship == NSURLRelationship.Other) {
            return nil
        }

        var httpd = objc_getAssociatedObject(self, key.httpd) as? HttpServer
        if httpd == nil {
            httpd = HttpServer()
            httpd!["/(.+)"] = HttpHandlers.directory(readAccessURL.path!)
            httpd!.start()
            objc_setAssociatedObject(self, key.httpd, httpd!, UInt(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
        }

        let target = URL.path!.substringFromIndex(advance(URL.path!.startIndex, count(readAccessURL.path!)))
        let url = NSURL(scheme: "http", host: "127.0.0.1:8080", path: target)
        return loadRequest(NSURLRequest(URL: url!));
    }
}

extension WKUserContentController {
    func removeUserScript(script: WKUserScript) {
        let scripts = userScripts
        removeAllUserScripts()
        for i in scripts {
            if i !== script {
                addUserScript(i as! WKUserScript)
            }
        }
    }
}
