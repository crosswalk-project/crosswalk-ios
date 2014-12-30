// Copyright (c) 2014 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation
import WebKit

public class XWalkChannel : NSObject, WKScriptMessageHandler {
    private let _name: String
    private weak var _webView: WKWebView!
    private var object: AnyObject!

    public var name: String { return _name }
    public weak var webView: WKWebView! { return _webView }

    public init(webView: WKWebView, name: String? = nil) {
        struct seq{
            static var num: UInt32 = 0
        }

        _webView = webView
        _name = name ?? "\(++seq.num)"
        super.init()
        webView.configuration.userContentController.addScriptMessageHandler(self, name: "\(_name)")
    }

    deinit {
        _webView.configuration.userContentController.removeScriptMessageHandlerForName("\(_name)")
        if _webView.URL != nil && object is XWalkExtension {
            evaluateJavaScript("delete \((object as XWalkExtension).namespace);", completionHandler:nil)
        }
    }

    public var jsAPIStub: String {
        var jsapi: String = ""

        // Generate JavaScript through introspection
        for var mlist = class_copyMethodList(object!.dynamicType, nil); mlist.memory != nil; mlist = mlist.successor() {
            let method:String = NSStringFromSelector(method_getName(mlist.memory))
            if method.hasPrefix("jsfunc_") && method.hasSuffix(":") {
                var args = method.componentsSeparatedByString(":")
                let name = args.first!.substringFromIndex(advance(method.startIndex, 7))
                args.removeAtIndex(0)
                args.removeLast()

                // deal with parameters without external name
                for i in 0...args.count-1 {
                    if args[i].isEmpty {
                        args[i] = "__\(i)"
                    }
                }

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
                jsapi += "\(stub)\n"
            } else if method.hasPrefix("jsprop_") && !method.hasSuffix(":") {
                let name = method.substringFromIndex(advance(method.startIndex, 7))
                let writable = object!.dynamicType.instancesRespondToSelector(Selector("setJsprop_\(name):"))
                let result = Invocation.call(object, selector: Selector("jsprop_\(name)"), arguments: nil)
                var val: AnyObject = result.object ?? result.number ?? NSNull()
                if val as? String != nil {
                    val = "'\(val)'"
                }
                jsapi += "exports.defineProperty('\(name)', \(JSON(val).toString()), \(writable));\n"
            }
        }
        return jsapi
    }

    public func bind(object: AnyObject, namespace: String) {
        self.object = object
        let delegate = object as? XWalkDelegate
        delegate?.didEstablishChannel?(self)

        // Inject JavaScript API
        var script = "(function(exports) {\n\n" +
            "'use strict';\n" +
            "\(jsAPIStub)\n\n" +
        "})(Extension.create('\(name)', '\(namespace)'));"
        if delegate?.didGenerateStub != nil {
            script = delegate!.didGenerateStub!(script)
        }

        _webView.injectScript(script)
        delegate?.didBindExtension?(namespace)
    }

    public func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage: WKScriptMessage) {
        let body = didReceiveScriptMessage.body as [String: AnyObject]
        if let method = body["method"] as? String {
            // Method call
            if let args = body["arguments"] as? [[String: AnyObject]] {
                if args.filter({$0 == [:]}).count > 0 {
                    // WKWebKit can't handle undefined type well
                    println("ERROR: parameters contain undefined value")
                    return
                }
                let inv = Invocation(name: "jsfunc_" + method)
                inv.appendArgument("", value: body["callid"])
                for a in args {
                    for (k, v) in a {
                        inv.appendArgument(k.hasPrefix("__") ? "" : k, value: v is NSNull ? nil : v)
                    }
                }
                if let result = inv.call(object) {
                    if result.isBool {
                        if result.boolValue {
//                          invokeJavaScript(".releaseArguments", arguments: [body["callid"]!])
                        }
                    } else {
                        NSException(name: "TypeError", reason: "The return value of native method must be BOOL type.", userInfo: nil).raise()
                    }
                }
            }
        } else if let prop = body["property"] as? String {
            // Property setting
            let inv = Invocation(name: "setJsprop_\(prop)")
            inv.appendArgument("", value: body["value"])
            inv.call(object)
        } else {
            // TODO: support user defined message?
            println("ERROR: Unknown message: \(body)")
        }
    }

    public func evaluateJavaScript(string: String, completionHandler: ((AnyObject!, NSError!)->Void)?) {
        // TODO: Should call completionHandler with an NSError object when webView is nil
        _webView.evaluateJavaScript(string, completionHandler: completionHandler)
    }
}
