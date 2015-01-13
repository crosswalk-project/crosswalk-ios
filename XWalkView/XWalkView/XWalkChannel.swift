// Copyright (c) 2014 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation
import WebKit

public class XWalkChannel : NSObject, WKScriptMessageHandler {
    private let _name: String
    private weak var _webView: WKWebView!
    private var _thread: NSThread = NSThread.mainThread()
    private var _namespace: String = ""

    private var instances: [Int: AnyObject] = [:]
    internal var mirror: XWalkReflection!
    private var userScript: WKUserScript?

    public var name: String { return _name }
    public weak var webView: WKWebView! { return _webView }
    public var thread: NSThread { return _thread }
    public var namespace: String { return _namespace }

    public init(webView: WKWebView, name: String? = nil) {
        struct seq{
            static var num: UInt32 = 0
        }

        _webView = webView
        _name = name ?? "\(++seq.num)"
        super.init()
        webView.configuration.userContentController.addScriptMessageHandler(self, name: "\(_name)")
    }

    public func bind(object: AnyObject, namespace: String, thread: NSThread? = nil) {
        _namespace = namespace
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
        let delegate = object as? XWalkDelegate
        if delegate?.didGenerateStub != nil {
            script = delegate!.didGenerateStub!(script)
        }

        userScript = _webView.injectScript(script)
        delegate?.didBindExtension?(self, instance: 0)
        instances[0] = object
    }

    public func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage: WKScriptMessage) {
        let body = didReceiveScriptMessage.body as [String: AnyObject]
        let instid = (body["instance"] as? NSNumber)?.integerValue ?? 0
        let callid = body["callid"] as? NSNumber ?? NSNumber(integer: 0)
        let args = [callid] + (body["arguments"] as? [AnyObject] ?? [])

        if let method = body["method"] as? String {
            // Invoke method
            if let object: AnyObject = instances[instid] {
                let selector = mirror.getMethod(method)
                if selector != nil {
                    Invocation.call(object, selector: selector, arguments: args, thread: _thread)
                } else {
                    println("ERROR: Method '\(method)' is not defined in class '\(object.dynamicType.description())'.")
                }
            } else {
                println("ERROR: Instance \(instid) does not exist.")
            }
        } else if let prop = body["property"] as? String {
            // Update property
            if let object: AnyObject = instances[instid] {
                var selector = mirror.getSetter(prop)
                if selector != nil {
                    let value: AnyObject = body["value"] ?? NSNull()
                    let original = mirror.getOriginalSetter(name)
                    if original != nil {
                        selector = original
                    }
                    Invocation.call(object, selector: selector, arguments: [value], thread: _thread)
                } else if mirror.hasProperty(prop) {
                    println("ERROR: Property '\(prop)' is readonly.")
                } else {
                    println("ERROR: Property '\(prop)' is not defined in class '\(object.dynamicType.description())'.")
                }
            } else {
                println("ERROR: Instance \(instid) does not exist.")
            }
        } else if instid > 0 && instances[instid] == nil {
            // Create instance
            let ctor: AnyObject = instances[0]!
            let object: AnyObject = Invocation.construct(ctor.dynamicType, initializer: mirror.constructor!, arguments: args)
            instances[instid] = object
            (object as? XWalkDelegate)?.didBindExtension?(self, instance: instid)
            // TODO: shoud call releaseArguments
        } else if instid < 0 && instances[-instid] != nil {
            // Destroy instance
            instances.removeValueForKey(-instid)
        } else if body["destroy"] != nil {
            // Destroy extension
            if _webView.URL != nil {
                evaluateJavaScript("delete \(_namespace);", completionHandler:nil)
            }
            _webView.configuration.userContentController.removeScriptMessageHandlerForName("\(_name)")
            if userScript != nil {
                _webView.configuration.userContentController.removeUserScript(userScript!)
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
