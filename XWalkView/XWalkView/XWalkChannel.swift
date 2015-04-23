// Copyright (c) 2014 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation
import WebKit

public class XWalkChannel : NSObject, WKScriptMessageHandler {
    public var mirror: XWalkReflection!
    public let name: String
    private(set) public weak var webView: WKWebView!
    private(set) public var thread: NSThread = NSThread.mainThread()
    private(set) public var namespace: String = ""

    private var instances: [Int: AnyObject] = [:]
    private var userScript: WKUserScript?

    public init(webView: WKWebView, name: String? = nil) {
        struct seq{
            static var num: UInt32 = 0
        }

        self.webView = webView
        self.name = name ?? "\(++seq.num)"
        super.init()
        webView.configuration.userContentController.addScriptMessageHandler(self, name: "\(self.name)")
    }

    public func bind(object: AnyObject, namespace: String, thread: NSThread) {
        self.namespace = namespace
        self.thread = thread

        mirror = XWalkReflection(cls: object.dynamicType)
        var script = XWalkStubGenerator(reflection: mirror).generate(name, namespace: namespace, object: object)
        let delegate = object as? XWalkDelegate
        script = delegate?.didGenerateStub?(script) ?? script

        userScript = webView.injectScript(script)
        delegate?.didBindExtension?(self, instance: 0)
        instances[0] = object
    }

    public func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage: WKScriptMessage) {
        let body = didReceiveScriptMessage.body as! [String: AnyObject]
        let instid = (body["instance"] as? NSNumber)?.integerValue ?? 0
        let callid = body["callid"] as? NSNumber ?? NSNumber(integer: 0)
        let args = [callid] + (body["arguments"] as? [AnyObject] ?? [])

        if let method = body["method"] as? String {
            // Invoke method
            if let object: AnyObject = instances[instid] {
                let delegate = object as? XWalkDelegate
                if delegate?.invokeNativeMethod != nil {
                    let selector = Selector("invokeNativeMethod:arguments:")
                    XWalkInvocation.asyncCallOnThread(thread, target: object, selector: selector, arguments: [method, args])
                } else if mirror.hasMethod(method) {
                    XWalkInvocation.asyncCallOnThread(thread, target: object, selector: mirror.getMethod(method), arguments: args)
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
                    XWalkInvocation.asyncCallOnThread(thread, target: object, selector: selector, arguments: [prop, value])
                } else if mirror.hasProperty(prop) {
                    let selector = mirror.getSetter(prop)
                    if selector != Selector() {
                        XWalkInvocation.asyncCallOnThread(thread, target: object, selector: selector, arguments: [value])
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
            let object: AnyObject = XWalkInvocation.constructOnThread(thread, `class`: ctor.dynamicType, initializer: mirror.constructor, arguments: args)
            instances[instid] = object
            (object as? XWalkDelegate)?.didBindExtension?(self, instance: instid)
            // TODO: shoud call releaseArguments
        } else if let object: AnyObject = instances[-instid] {
            // Destroy instance
            instances.removeValueForKey(-instid)
            (object as? XWalkDelegate)?.didUnbindExtension?()
        } else if body["destroy"] != nil {
            // Destroy extension
            if webView.URL != nil {
                evaluateJavaScript("delete \(namespace);", completionHandler:nil)
            }
            webView.configuration.userContentController.removeScriptMessageHandlerForName("\(name)")
            if userScript != nil {
                webView.configuration.userContentController.removeUserScript(userScript!)
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
            webView.evaluateJavaScript(string, completionHandler: completionHandler)
        } else {
            weak var weakSelf = self
            dispatch_async(dispatch_get_main_queue()) {
                if let strongSelf = weakSelf {
                    strongSelf.webView.evaluateJavaScript(string, completionHandler: completionHandler)
                }
            }
        }
    }
}
