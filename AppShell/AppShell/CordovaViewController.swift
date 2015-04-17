// Copyright (c) 2015 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Cordova
import UIKit
import WebKit
import XWalkView

class ViewController: CDVViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        var start_url = "index.html"
        var xwalk_extensions = ["Extension.load"]
        if let plistPath = NSBundle.mainBundle().pathForResource("manifest", ofType: "plist") {
            if let manifest = NSDictionary(contentsOfFile: plistPath) {
                start_url = manifest["start_url"] as? String ?? start_url
                xwalk_extensions = manifest["xwalk_extensions"] as? [String] ?? xwalk_extensions
            }
        }

        let webview = WKWebView(frame: view.frame, configuration: WKWebViewConfiguration())
        webview.navigationDelegate = self
        webview.scrollView.bounces = false
        view.addSubview(webview)

        for name in xwalk_extensions {
            var ext: AnyObject? = nil;
            if name == "xwalk.cordova" {
                ext = XWalkExtensionFactory.createExtension(name, initializer: "initWithViewController:", arguments: [self])
            } else {
                ext = XWalkExtensionFactory.createExtension(name)
            }
            if let validExtension: AnyObject = ext {
                webview.loadExtension(validExtension, namespace: name)
            }
        }

        if let root = NSBundle.mainBundle().resourceURL?.URLByAppendingPathComponent("www") {
            var error: NSError?
            let url = root.URLByAppendingPathComponent(start_url)
            if url.checkResourceIsReachableAndReturnError(&error) {
                webview.loadFileURL(url, allowingReadAccessToURL: root)
            } else {
                webview.loadHTMLString(error!.description, baseURL: nil)
            }
        }
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}
