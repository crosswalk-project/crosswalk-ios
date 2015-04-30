// Copyright (c) 2015 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import UIKit
import WebKit
import XCTest
import XWalkView


class ChannelTestExtension: XWalkExtension {
    var expectation: XCTestExpectation? = nil

    override func didBindExtension(channel: XWalkChannel!, instance: Int) {
        expectation?.fulfill()
    }
}

class XWalkChannelTest: XCTestCase, WKNavigationDelegate {
    var webview: WKWebView? = nil
    var channel: XWalkChannel? = nil

    var executionContext: ExecutionContext? = nil

    private let extensionName = "xwalk.test.channel"

    override func setUp() {
        super.setUp()
        webview = WKWebView(frame: CGRectZero, configuration: WKWebViewConfiguration())
        webview?.navigationDelegate = self

        XWalkExtensionFactory.register(extensionName, cls: ChannelTestExtension.self)
        channel = XWalkChannel(webView: webview!)

        var ext = XWalkExtensionFactory.createExtension(extensionName) as! ChannelTestExtension
        channel?.bind(ext, namespace: extensionName, thread: webview!.extensionThread)
    }

    override func tearDown() {
        super.tearDown()
        webview = nil
        channel = nil
    }

    func webView(webView: WKWebView, didCommitNavigation navigation: WKNavigation!) {
        if let context = self.executionContext {
            self.channel?.evaluateJavaScript(context.scriptToEvaluate, completionHandler: {(object, error) in
                if let handler = context.completionHandler {
                    handler(object, error)
                }
            })
        }
    }

    func testBind() {
        var ext = XWalkExtensionFactory.createExtension(extensionName) as! ChannelTestExtension
        ext.expectation = self.expectationWithDescription("testBindExpectation")
        channel?.bind(ext, namespace: extensionName, thread: webview!.extensionThread)

        self.waitForExpectationsWithTimeout(0.1, handler:{ (error) in
            if let e = error {
                XCTFail("testBind Failed")
            }
        })
    }

    func testEvaluateJavaScript() {
        var expectation = self.expectationWithDescription("ExpectationEvaluateJavaScript")
        var executionContext = ExecutionContext(script: "typeof(\(extensionName));", completionHandler:{ (object, error) in
            if error != nil {
                println("Failed to evaluate javascript, error:\(error)")
            } else {
                expectation.fulfill()
            }
        })

        self.executionContext = executionContext

        webview?.loadHTMLString("<html></html>", baseURL: nil)

        self.waitForExpectationsWithTimeout(2, handler: { (error) in
            if let e = error {
                XCTFail("testEvaluateJavaScript failed, with error:\(e)")
            }
        })
    }
}

