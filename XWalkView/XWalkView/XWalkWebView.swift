// Copyright (c) 2014 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import WebKit

public class XWalkView : WKWebView {
    private static let httpServer: GCDWebServer = GCDWebServer()
    private var extensionThread: XWalkThread?
    private var channels: Dictionary<String, XWalkChannel> = [:]

    deinit {
        for channel in channels.values {
            channel.destroyExtension()
        }
    }

    public func loadExtension(object: AnyObject, namespace: String) {
        if extensionThread == nil {
            prepareForExtension()
            extensionThread = XWalkThread()
            extensionThread?.start()
        }
        var channel = XWalkChannel(webView: self)
        channel.bind(object, namespace: namespace, thread: extensionThread)
        assert(channels[channel.name] == nil, "Duplicate channel name:\(channel.name)")
        channels[channel.name] = channel
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
        let bundle = NSBundle(forClass: self.dynamicType)
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

        let port: UInt = 8080
        if !self.dynamicType.httpServer.running {
            self.dynamicType.httpServer.addGETHandlerForBasePath("/", directoryPath: readAccessURL.path!, indexFilename: nil, cacheAge: 3600, allowRangeRequests: true)
            self.dynamicType.httpServer.startWithPort(port, bonjourName: nil)
        }

        let target = URL.path!.substringFromIndex(advance(URL.path!.startIndex, count(readAccessURL.path!)))
        let url = NSURL(scheme: "http", host: "127.0.0.1:\(port)", path: target)
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
