// Copyright (c) 2014 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import UIKit
import WebKit
import XWalkView

class ViewController: UIViewController {
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
        webview.scrollView.bounces = false
        view.addSubview(webview)

        for name in xwalk_extensions {
            if let ext: AnyObject = XWalkExtensionFactory.createExtension(name) {
                webview.loadExtension(ext, namespace: name)
            }
        }

        if let path = NSBundle.mainBundle().pathForResource(
                start_url.lastPathComponent.stringByDeletingPathExtension,
                ofType: start_url.pathExtension,
                inDirectory: "www/" + start_url.stringByDeletingLastPathComponent) {
            webview.loadRequest(NSURLRequest(URL: NSURL.fileURLWithPath(path)!));
        }
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}
