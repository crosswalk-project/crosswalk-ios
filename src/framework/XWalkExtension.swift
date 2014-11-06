// Copyright (c) 2014 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation
import WebKit
import SwiftyJSON

public class XWalkExtension: NSObject, WKScriptMessageHandler {
    public final let name: String!
    public final weak var webView: WKWebView!
    private var properties: Dictionary<String, AnyObject> = [:]

    public init(name: String) {
        super.init()
        self.name = name
    }

    public var jsAPIStub: String {
        let bundle : NSBundle = NSBundle(forClass: self.dynamicType)
        if let path = bundle.pathForResource(self.name, ofType: "js") {
            if let file = NSFileHandle(forReadingAtPath: path) {
                if let api = NSString(data: file.readDataToEndOfFile(), encoding: NSUTF8StringEncoding) {
                    return api
                }
            }
            println("ERROR: Can't read stub file '\(self.name).js'")
        } else {
            println("ERROR: Stub file '\(self.name).js' not found")
        }
        return ""
    }

    public func userContentController(userContentController: WKUserContentController,
        didReceiveScriptMessage message: WKScriptMessage) {
        let body = message.body as [String: AnyObject]
        if let method = body["method"] as? String {
            // Method call
            let args = body["arguments"] as? [[String: AnyObject]]
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
            f = name + function
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
            let cmd = "\(self.name).\(name) = \(json); \(self.name).\(name);"
            self.evaluate(cmd, success: { (obj)->Void in
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
        webView.evaluateJavaScript(string, completionHandler: completionHandler)
    }
}
