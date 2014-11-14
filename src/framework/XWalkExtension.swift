// Copyright (c) 2014 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation
import WebKit
import SwiftyJSON

public class XWalkExtension: NSObject, WKScriptMessageHandler {
    public final let name: String!
    public final var namespace: String!
    public final var id: Int = 0
    internal weak var webView: WKWebView?
    private var properties: Dictionary<String, AnyObject> = [:]

    public init(name: String) {
        super.init()
        self.name = name
        namespace = name
    }

    private var seqenceNumber : Int {
        struct seq{
            static var num: Int = 0
        }
        return ++seq.num
    }

    public var jsAPIStub: String {
        let bundle : NSBundle = NSBundle(forClass: self.dynamicType)
        if let path = bundle.pathForResource(name, ofType: "js") {
            if let file = NSFileHandle(forReadingAtPath: path) {
                if let api = NSString(data: file.readDataToEndOfFile(), encoding: NSUTF8StringEncoding) {
                    return api
                }
            }
            println("ERROR: Can't read stub file '\(name).js'")
        } else {
            println("ERROR: Stub file '\(name).js' not found")
        }
        return ""
    }

    public func attach(webView: WKWebView, namespace: String? = nil) {
        let controller = webView.configuration.userContentController
        id = seqenceNumber
        self.namespace = namespace ?? name

        // Inject JavaScript API
        let code = "(function(exports) {" +
            "   'use strict';" +
            "    \(jsAPIStub)" +
            "})(Extension.create(\(id), '\(self.namespace)'));"
        let script = WKUserScript(
            source: code,
            injectionTime: WKUserScriptInjectionTime.AtDocumentStart,
            forMainFrameOnly: false)
        controller.addUserScript(script)

        // Register message handler
        controller.addScriptMessageHandler(self, name: "\(id)")

        self.webView = webView
        if webView.URL != nil {
            evaluate(code)
        }
    }

    public func detach() {
        let controller = webView!.configuration.userContentController
        controller.removeScriptMessageHandlerForName("\(id)")
        // TODO: How to remove user script?
        //controller.userScripts.removeAtIndex(id)
        if webView!.URL != nil {
            // Cleanup extension code in current context
            evaluate("delete \(namespace);")
        }
        webView = nil
        id = 0
    }

    public func userContentController(userContentController: WKUserContentController,
        didReceiveScriptMessage message: WKScriptMessage) {
        let body = message.body as [String: AnyObject]
        if let method = body["method"] as? String {
            // Method call
            let args = body["arguments"] as? [[String: AnyObject]]
            if args?.filter({$0 == [:]}).count > 0 {
                // WKWebKit can't handle undefined type well
                println("ERROR: parameters contain undefined value")
                return
            }
            let inv = Invocation(method: "js_" + method, arguments: args)
            inv.call(self)
        } else if let prop = body["property"] as? String {
            // Property setting
            let newValue: AnyObject? = body["value"]
            let oldValue: AnyObject? = properties["prop"]
            willSetProperty(prop, newValue: newValue)
            if newValue != nil {
                properties.updateValue(newValue!, forKey: prop)
            } else {
                properties.removeValueForKey(prop)
            }
            didSetProperty(prop, oldValue: oldValue)
        } else {
            // TODO: support user defined message?
            println("ERROR: Unknown message: \(body)")
        }
    }

    public func invokeCallback(callID: Int32, key: String?, arguments: [AnyObject]?) {
        var arg : [AnyObject] = [ NSNumber(int: callID), key ?? NSNull(), arguments ?? [] ]
        invokeJavaScript(".invokeCallback", arguments: arg)
    }

    public func invokeJavaScript(function: String, arguments: [AnyObject] = []) {
        var f: String = function
        if f[f.startIndex] == "." {
            // Invoke a method of this object
            f = namespace + function
        }
        if let json = JSON(arguments).rawString() {
            // Remove the top level brackets
            let a = json[Range<String.Index>(start: json.startIndex.successor(), end: json.endIndex.predecessor())]
            evaluate("\(f)(\(a));")
        } else {
            println("ERROR: Invalid argument list: \(arguments)")
        }
    }

    public subscript(name: String) -> AnyObject? {
        get {
            return properties[name]
        }
        set(value) {
            let val: AnyObject = value ?? NSNull()
            //properties.updateValue(val, forKey: name)
            let json = JSON(val).rawString()!
            let cmd = "\(namespace).\(name) = \(json); \(namespace).\(name);"
            evaluate(cmd, success: { (obj)->Void in
                self.properties.updateValue(obj, forKey: name)
                return
            })
        }
    }
    // Override if you want to monitor changing of properies.
    public func willSetProperty(name: String, newValue: AnyObject?) {
    }
    public func didSetProperty(name: String, oldValue: AnyObject?) {
    }

    public override func doesNotRecognizeSelector(aSelector: Selector) {
        let method = NSStringFromSelector(aSelector)
        println("Error: Method '\(method)' not found in extension '\(name)'")
    }
}

extension XWalkExtension {
    // Helper functions to evaluate JavaScript
    public func evaluate(string: String) {
        evaluate(string, success: nil)
    }
    public func evaluate(string: String, error: ((NSError)->Void)?) {
        evaluate(string, completionHandler: { (obj, err)->Void in
            if err != nil { error?(err) }
        })
    }
    public func evaluate(string: String, success: ((AnyObject!)->Void)?) {
        evaluate(string, completionHandler: { (obj, err) -> Void in
            err == nil ? success?(obj) : println("ERROR: Failed to execute script, \(err)")
            return    // To make compiler happy
        })
    }
    public func evaluate(string: String, success: ((AnyObject!)->Void)?, error: ((NSError!)->Void)?) {
        evaluate(string, completionHandler: { (obj, err)->Void in
            err == nil ? success?(obj) : error?(err)
            return    // To make compiler happy
        })
    }
    public func evaluate(string: String, completionHandler: ((AnyObject!, NSError!)->Void)?) {
        // TODO: Should call completionHandler with an NSError object when webView is nil
        webView?.evaluateJavaScript(string, completionHandler: completionHandler)
    }
}
