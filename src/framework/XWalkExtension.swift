// Copyright (c) 2014 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation
import WebKit
import SwiftyJSON

public class XWalkExtension: NSObject, WKScriptMessageHandler {
    public final let name: String!
    public final weak var webView: WKWebView!
    private final var properties: Dictionary<String, AnyObject> = [:]

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
        var args = (key != nil) ? ("'" + key! + "'") : "null"
        if arguments != nil && arguments!.count > 0 {
            args += ", " + JSON(arguments!).rawString()!
        }
        var cmd = "\(name).invokeCallback(\(callID), \(args));"
        webView.evaluateJavaScript(cmd, completionHandler: { (obj, err) -> Void in
            if err != nil {
                println("ERROR: Failed to execute script, \(err)")
            }
        })
    }

    public subscript(name: String) -> AnyObject? {
        get {
            return properties[name]
        }
        set(value) {
            let val: AnyObject = value ?? NSNull()
            //properties.updateValue(val, forKey: name)
            let json = JSON(val).rawString()!
            webView.evaluateJavaScript("\(self.name).\(name) = \(json); \(self.name).\(name);", completionHandler: { (obj, err) -> Void in
                if err == nil {
                    self.properties.updateValue(obj, forKey: name)
                } else {
                    println("ERROR: Failed to execute script, \(err)")
                }
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
