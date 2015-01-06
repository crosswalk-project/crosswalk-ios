// Copyright (c) 2014 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import UIKit
import WebKit
import CrosswalkLite

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let webview = WKWebView(frame: view.frame, configuration: WKWebViewConfiguration())
        webview.scrollView.scrollEnabled = false
        view.addSubview(webview)

        /*if let ext = XWalkExtensionFactory.createExtension("xwalk.sample.echo", parameter: "prefix: ") {
            webview.loadExtension(ext, namespace: "echo")
        }*/
        if let ext: AnyObject = XWalkExtensionFactory.createExtension("Extension.loader") {
            webview.loadExtension(ext, namespace: "Extension.loader")
        }

        if let path = NSBundle.mainBundle().pathForResource("echo", ofType: "html") {
            webview.loadRequest(NSURLRequest(URL: NSURL.fileURLWithPath(path)!));
        }
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}
