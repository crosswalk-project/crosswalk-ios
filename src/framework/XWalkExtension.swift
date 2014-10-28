// Copyright (c) 2014 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation
import WebKit
import SwiftyJSON

func nameWithoutDot(name: String) -> String {
    return join("", name.componentsSeparatedByString("."))
}

func extensionCodes(name: String) -> String {
    return join("\n", [
        "var extension = (function () {",
        "    var _lastCallID = 0;",
        "    var _callbacks = [];",
        "    var _listeners = [];",
        "    var invokeNative = function(body) {",
        "        if (body == undefined || typeof(body.method) != 'string') {",
        "            console.error('Invalid invocation');",
        "            return;",
        "        }",
        "        window.webkit.messageHandlers.\(nameWithoutDot(name)).postMessage(body);",
        "    };",
        "    var addCallback = function(callback) {",
        "        while (_callbacks[_lastCallID] != undefined) ++_lastCallID;",
        "        _callbacks[_lastCallID] = callback;",
        "        return _lastCallID;",
        "    };",
        "    var removeCallback = function(callID) {",
        "        delete _callbacks[callID];",
        "        _lastCallID = callID;",
        "    };",
        "    var invokeCallback = function(callID, key, args) {",
        "        var func = _callbacks[callID];",
        "        if (typeof(func) == 'object')  func = func[key];",
        "        if (typeof(func) == 'function')  func.apply(null, args);",
        "        removeCallback(callID);",
        "    };",
        "    return {",
        "        'invokeNative'   : invokeNative,",
        "        'addCallback'    : addCallback,",
        "        'removeCallback' : removeCallback,",
        "        'invokeCallback' : invokeCallback,",
        "    };",
        "})();"])
}

func codeToEnsureNamespace(extensionName: String) -> String {
    var namespaceArray = extensionName.componentsSeparatedByString(".")
    var namespace: String = ""
    var result: String = ""
    for var i = 0; i < namespaceArray.count; ++i {
        if (countElements(namespace) > 0) {
            namespace += "."
        }
        namespace += namespaceArray[i]
        result += namespace + " = " + namespace + " || {}; "
    }
    return result
}

public class XWalkExtension: NSObject, WKScriptMessageHandler {
    public final let name: String!
    public final let jsAPI: String!
    final var webView: WKWebView!

    override init() {
    }
    init?(WebView: WKWebView) {
        super.init()
        self.webView = WebView

        let bundle : NSBundle = NSBundle(forClass: self.dynamicType)
        if let mfpath = bundle.pathForResource("manifest", ofType: "plist") {
            if let manifest = NSDictionary(contentsOfFile: mfpath) {
                self.name = manifest["name"] as? String
                var path = manifest["jsapi"] as? String
                if (self.name == nil || path == nil) {
                    return nil
                }

                // Read JavaScript stub file
                path = bundle.pathForResource(path!.stringByDeletingPathExtension, ofType: path!.pathExtension)
                if path == nil { return nil }
                let file = NSFileHandle(forReadingAtPath: path!)
                if file == nil { return nil }
                self.jsAPI = NSString(data: file!.readDataToEndOfFile(), encoding: NSUTF8StringEncoding)
                if self.jsAPI == nil { return nil }

                // Inject into JavaScript context
                let codes = join("\n", [
                    "var \(codeToEnsureNamespace(self.name))",
                    "(function() {",
                    "    \(extensionCodes(self.name))",
                    "    var exports = {};",
                    "    (function() {'use strict'; ",
                    "        \(jsAPI)})();",
                    "    exports.extension = extension;",
                    "    \(self.name) = exports;",
                    "})();"])
                let userScript = WKUserScript(source: codes, injectionTime:
                    WKUserScriptInjectionTime.AtDocumentStart, forMainFrameOnly: false)
                webView.configuration.userContentController.addUserScript(userScript)
                webView.configuration.userContentController.addScriptMessageHandler(self, name: nameWithoutDot(self.name))
            }
        }
    }

    public func userContentController(userContentController: WKUserContentController,
        didReceiveScriptMessage message: WKScriptMessage) {
            let body = message.body as [String: AnyObject]
            let method = body["method"]! as String
            let args = body["arguments"]! as [[String: AnyObject]]
            let inv = Invocation(method: method, arguments: args)
            inv.call(self)
    }
    
    public func invokeCallback(callID: Int32, key: String?, arguments: [AnyObject]?) {
        var args = (key != nil) ? ("'" + key! + "'") : "null"
        if arguments != nil && arguments!.count > 0 {
            args += ", " + JSON(arguments!).rawString()!
        }
        var cmd = "\(name).extension.invokeCallback(\(callID), \(args));"
        webView.evaluateJavaScript(cmd, completionHandler: { (obj, err) -> Void in
            if err != nil {
                println("Failed to execute script, with error:\(err)")
            }
        })
    }
}

