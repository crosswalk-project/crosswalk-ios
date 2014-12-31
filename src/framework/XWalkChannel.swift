// Copyright (c) 2014 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation
import WebKit

public class XWalkChannel : NSObject, WKScriptMessageHandler {
    private let _name: String
    private weak var _webView: WKWebView!
    private var object: AnyObject!
    internal var mirror: XWalkReflection!

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

    public func bind(object: AnyObject, namespace: String) {
        let delegate = object as? XWalkDelegate
        delegate?.didEstablishChannel?(self)

        mirror = XWalkReflection(cls: object.dynamicType)
        var script = XWalkStubGenerator(reflection: mirror).generate(_name, namespace: namespace, object: object)
        if delegate?.didGenerateStub != nil {
            script = delegate!.didGenerateStub!(script)
        }

        _webView.injectScript(script)
        delegate?.didBindExtension?(namespace)
        self.object = object
    }

    public func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage: WKScriptMessage) {
        let body = didReceiveScriptMessage.body as [String: AnyObject]
        if let method = body["method"] as? String {
            // Method call
            if let callid = body["callid"] as? NSNumber {
                if let selector = mirror.getMethod(method) {
                    let args = body["arguments"] as? [AnyObject] ?? []
                    let result = Invocation.call(object, selector: selector, arguments: [callid] + args)
                    if result.isBool {
                        if result.boolValue && object is XWalkExtension {
                            (object as XWalkExtension).invokeJavaScript(".releaseArguments", arguments: [callid])
                        }
                    } else {
                        NSException(name: "TypeError", reason: "The return value of native method must be BOOL type.", userInfo: nil).raise()
                    }
                } else {
                    println("ERROR: Method '\(method)' is not defined in class '\(NSStringFromClass(object!.dynamicType))'.")
                }
            }
        } else if let prop = body["property"] as? String {
            // Property setting
            if let selector = mirror.getSetter(prop) {
                let value: AnyObject = body["value"] ?? NSNull()
                Invocation.call(object, selector: selector, arguments: [value])
            } else if mirror.hasProperty(prop) {
                println("ERROR: Property '\(prop)' is readonly.")
            } else {
                println("ERROR: Property '\(prop)' is not defined in class '\(NSStringFromClass(object!.dynamicType))'.")
            }
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
