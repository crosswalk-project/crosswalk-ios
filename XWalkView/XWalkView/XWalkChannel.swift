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
    public var mirror: XWalkReflection!
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
        var script = XWalkStubGenerator(reflection: mirror).generate(_name, namespace: namespace, object: object)
        let delegate = object as? XWalkDelegate
        script = delegate?.didGenerateStub?(script) ?? script

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
                let delegate = object as? XWalkDelegate
                if delegate?.invokeNativeMethod != nil {
                    let selector = Selector("invokeNativeMethod:arguments:")
                    Invocation.call(object, selector: selector, arguments: [method, args], thread: _thread)
                } else if mirror.hasMethod(method) {
                    Invocation.call(object, selector: mirror.getMethod(method), arguments: args, thread: _thread)
                } else {
                    println("ERROR: Method '\(method)' is not defined in class '\(object.dynamicType.description())'.")
                }
            } else {
                println("ERROR: Instance \(instid) does not exist.")
            }
        } else if let prop = body["property"] as? String {
            // Update property
            if let object: AnyObject = instances[instid] {
                let value: AnyObject = body["value"] ?? NSNull()
                let delegate = object as? XWalkDelegate
                if delegate?.setNativeProperty != nil {
                    let selector = Selector("setNativeProperty:value:")
                    Invocation.call(object, selector: selector, arguments: [prop, value], thread: _thread)
                } else if mirror.hasProperty(prop) {
                    let selector = mirror.getSetter(prop)
                    if selector != Selector() {
                        Invocation.call(object, selector: selector, arguments: [value], thread: _thread)
                    } else {
                        println("ERROR: Property '\(prop)' is readonly.")
                    }
                } else {
                    println("ERROR: Property '\(prop)' is not defined in class '\(object.dynamicType.description())'.")
                }
            } else {
                println("ERROR: Instance \(instid) does not exist.")
            }
        } else if instid > 0 && instances[instid] == nil {
            // Create instance
            let ctor: AnyObject = instances[0]!
            let object: AnyObject = Invocation.construct(ctor.dynamicType, initializer: mirror.constructor, arguments: args)
            instances[instid] = object
            (object as? XWalkDelegate)?.didBindExtension?(self, instance: instid)
            // TODO: shoud call releaseArguments
        } else if let object: AnyObject = instances[-instid] {
            // Destroy instance
            instances.removeValueForKey(-instid)
            (object as? XWalkDelegate)?.didUnbindExtension?()
        } else if body["destroy"] != nil {
            // Destroy extension
            if _webView.URL != nil {
                evaluateJavaScript("delete \(_namespace);", completionHandler:nil)
            }
            _webView.configuration.userContentController.removeScriptMessageHandlerForName("\(_name)")
            if userScript != nil {
                _webView.configuration.userContentController.removeUserScript(userScript!)
            }
            for (_, object) in instances {
                (object as? XWalkDelegate)?.didUnbindExtension?()
            }
            instances.removeAll(keepCapacity: false)
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
