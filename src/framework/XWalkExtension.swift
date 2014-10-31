// Copyright (c) 2014 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation
import WebKit
import SwiftyJSON

public class XWalkExtension: NSObject, WKScriptMessageHandler {
    let name: String!
    weak var webView: WKWebView!

    public init(name: String) {
        super.init()
        self.name = name
    }

    public func getJavaScriptStub() -> String {
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
            let method = body["method"]! as String
            let args = body["arguments"]! as [[String: AnyObject]]
            let inv = Invocation(method: method, arguments: args)
            inv.call(self)
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
}
