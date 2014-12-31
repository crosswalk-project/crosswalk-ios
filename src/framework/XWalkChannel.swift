// Copyright (c) 2014 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation
import WebKit

public class XWalkChannel : NSObject, WKScriptMessageHandler {
    private let _name: String
    private weak var _webView: WKWebView!
    private var _thread: NSThread = NSThread.mainThread()

    private var object: AnyObject!
    internal var mirror: XWalkReflection!

    public var name: String { return _name }
    public weak var webView: WKWebView! { return _webView }
    public var thread: NSThread { return _thread }

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

    public func bind(object: AnyObject, namespace: String, thread: NSThread? = nil) {
        let delegate = object as? XWalkDelegate
        delegate?.didEstablishChannel?(self)

        _thread = thread ?? _webView.extensionThread
        if _thread is XWalkThread && !_thread.executing {
            _thread.start()
        }

        mirror = XWalkReflection(cls: object.dynamicType)
        if object is XWalkExtension {
            // Do method swizzling
            for name in mirror.allMembers {
                if !mirror.wrapMethod(name, impl: xwalkExtensionMethod) {
                    mirror.wrapSetter(name, impl: xwalkExtensionSetter)
                }
            }
        }

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
                    Invocation.call(object, selector: selector, arguments: [callid] + args, thread: _thread)
                } else {
                    println("ERROR: Method '\(method)' is not defined in class '\(NSStringFromClass(object!.dynamicType))'.")
                }
            }
        } else if let prop = body["property"] as? String {
            // Property setting
            if var selector = mirror.getSetter(prop) {
                let value: AnyObject = body["value"] ?? NSNull()
                if let original = mirror.getOriginalSetter(name) {
                    selector = original
                }
                Invocation.call(object, selector: selector, arguments: [value], thread: _thread)
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
        if NSThread.isMainThread() {
            _webView.evaluateJavaScript(string, completionHandler: completionHandler)
        } else {
            dispatch_async(dispatch_get_main_queue()) {
                self._webView.evaluateJavaScript(string, completionHandler: completionHandler)
            }
        }
    }
}
