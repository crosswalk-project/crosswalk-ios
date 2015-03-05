// Copyright (c) 2015 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import UIKit
import WebKit
import XCTest
import XWalkView

class WebViewExtension: XWalkExtension {
}

class XWalkWebViewTests: XCTestCase {
    var webview: WKWebView? = nil

    override func setUp() {
        super.setUp()
        webview = WKWebView(frame: CGRectZero, configuration: WKWebViewConfiguration())
    }

    override func tearDown() {
        super.tearDown()
        webview = nil
    }

    func testExtensionThread() {
        XCTAssertNotNil(webview?.extensionThread, "Failed to retrive extensionThread")
        var thread: NSThread = NSThread()
        webview!.extensionThread = thread
        XCTAssertEqual(thread, webview!.extensionThread)
    }

    func testLoadExtension() {
        XWalkExtensionFactory.register("WebViewExtension", cls:WebViewExtension.self)
        if let ext: AnyObject = XWalkExtensionFactory.createExtension("WebViewExtension") {
            webview?.loadExtension(ext, namespace: name)
        } else {
            XCTFail("testLoadExtension Failed")
        }
    }

    func testLoadFileURL() {
        var bundle = NSBundle(identifier:"org.crosswalk-project.XWalkViewTests")
        if let root = bundle?.bundleURL.URLByAppendingPathComponent("www") {
            var error: NSError?
            let url = root.URLByAppendingPathComponent("webviewTest.html")
            if url.checkResourceIsReachableAndReturnError(&error) {
                webview?.loadFileURL(url, allowingReadAccessToURL: root)
                XCTAssert(true, "testLoadFileURL Passed")
                return
            }
        }
        XCTFail("testLoadFileURL Failed")
    }

}

