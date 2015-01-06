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
        view.addSubview(webview)

        let extensionName = "xwalk.experimental.system"
        if let ext: AnyObject = XWalkExtensionFactory.createExtension(extensionName) {
            webview.loadExtension(ext, namespace: extensionName)
        }

        if let path = NSBundle.mainBundle().pathForResource("index", ofType: "html", inDirectory:"www") {
            webview.loadRequest(NSURLRequest(URL: NSURL.fileURLWithPath(path)!));
        }
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}
