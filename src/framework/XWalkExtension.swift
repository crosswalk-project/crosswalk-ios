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
        var jsapi: String = ""

        // Generate JavaScript through introspection
        for var mlist = class_copyMethodList(self.dynamicType, nil); mlist.memory != nil; mlist = mlist.successor() {
            let method:String = NSStringFromSelector(method_getName(mlist.memory))
            if method.hasPrefix("jsfunc_") && method.hasSuffix(":") {
                var args = method.componentsSeparatedByString(":")
                let name = args.first!.substringFromIndex(advance(method.startIndex, 7))
                args.removeAtIndex(0)
                args.removeLast()

                var stub = "this.invokeNative(\"\(name)\", ["
                var isPromise = false
                for a in args {
                    if a != "_Promise" {
                        stub += "\n        {'\(a)': \(a)},"
                    } else {
                        assert(!isPromise)
                        isPromise = true
                        stub += "\n        {'\(a)': [resolve, reject]},"
                    }
                }
                if args.count > 0 {
                    stub.removeAtIndex(stub.endIndex.predecessor())
                }
                stub += "\n    ]);"
                if isPromise {
                    stub = "\n    ".join(stub.componentsSeparatedByString("\n"))
                    stub = "var _this = this;\n    return new Promise(function(resolve, reject) {\n        _" + stub + "\n    });"
                }
                stub = "exports.\(name) = function(" + ", ".join(args) + ") {\n    \(stub)\n}"
                println(stub)
                jsapi += "\(stub)\n"
            } else if method.hasPrefix("jsprop_") && !method.hasSuffix(":") {
                let name = method.substringFromIndex(advance(method.startIndex, 7))
                let writable = self.dynamicType.instancesRespondToSelector(NSSelectorFromString("setJsprop_\(name):"))
                var val: AnyObject = Invocation.call(self, method: method_getName(mlist.memory), arguments: nil)
                if val.isKindOfClass(NSString.classForCoder()) {
                    val = NSString(format: "'\(val as String)'")
                }
                jsapi += "exports.defineProperty('\(name)', \(JSON(val).rawString()!), \(writable));\n"
            }
            //println("Method : \(method), \(NSString(UTF8String: method_getTypeEncoding(mlist.memory))!)")
        }

        // Append the content of file if exist.
        let bundle : NSBundle = NSBundle(forClass: self.dynamicType)
        if let path = bundle.pathForResource(name, ofType: "js") {
            if let file = NSFileHandle(forReadingAtPath: path) {
                if let txt = NSString(data: file.readDataToEndOfFile(), encoding: NSUTF8StringEncoding) {
                    jsapi += txt
                } else {
                    println("ERROR: Encoding of file '\(name).js' must be UTF-8")
                }
            }
        }

        return jsapi
    }

    public func attach(webView: WKWebView, namespace: String? = nil) {
        let controller = webView.configuration.userContentController
        id = seqenceNumber
        self.namespace = namespace ?? name

        // Inject JavaScript API
        let code = "(function(exports) {\n\n" +
            "'use strict';\n" +
            "\(jsAPIStub)\n\n" +
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
            if var args = body["arguments"] as? [[String: AnyObject]] {
                if args.filter({$0 == [:]}).count > 0 {
                    // WKWebKit can't handle undefined type well
                    println("ERROR: parameters contain undefined value")
                    return
                }
                args = Array<[String: AnyObject]>(args)
                args.insert(["id": body["callid"]!], atIndex: 0)
                let inv = Invocation(method: "jsfunc_" + method, arguments: args)
                if inv.call(self) == nil {
                    invokeJavaScript(".releaseArguments", arguments: [body["callid"]!])
                }
            }
        } else if let prop = body["property"] as? String {
            // Property setting
            var args = [ ["val": body["value"]!] ]
            let inv = Invocation(method: "setJsprop_\(prop)", arguments: args)
            inv.call(self)
        } else {
            // TODO: support user defined message?
            println("ERROR: Unknown message: \(body)")
        }
    }

    public func invokeCallback(id: UInt32, key: String? = nil, arguments: [AnyObject] = []) {
        let args = NSArray(array: [NSNumber(unsignedInt: id), key ?? NSNull(), arguments])
        invokeJavaScript(".invokeCallback", arguments: args)
    }
    public func invokeCallback(id: UInt32, index: UInt32, arguments: [AnyObject] = []) {
        let args = NSArray(array: [NSNumber(unsignedInt: id), NSNumber(unsignedInt: index), arguments])
        invokeJavaScript(".invokeCallback", arguments: args)
    }
    public func invokeJavaScript(function: String, arguments: [AnyObject] = []) {
        var f = function
        var this = "null"
        if f[f.startIndex] == "." {
            // Invoke a method of this object
            f = namespace + function
            this = namespace
        }
        if let json = JSON(arguments).rawString() {
            evaluate("\(f).apply(\(this), \(json));")
        } else {
            println("ERROR: Invalid argument list: \(arguments)")
        }
    }

    public subscript(name: String) -> AnyObject? {
        get {
            let inv = Invocation(method: "jsprop_\(name)", arguments: nil)
            return inv.call(self)
        }
        set(value) {
            var val: AnyObject = value ?? NSNull()
            if val.isKindOfClass(NSString.classForCoder()) {
                val = NSString(format: "'\(val as String)'")
            }
            let json = JSON(val).rawString()!
            let cmd = "\(namespace).\(name) = \(json);"
            evaluate(cmd)
            // Native property updating will be triggered by JavaScrpt property setter.
        }
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
            err == nil ? success?(obj) : println("ERROR: Failed to execute script, \(err)\n------------\n\(string)\n------------")
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
