// Copyright (c) 2014 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation
import UIKit
import WebKit
import CrosswalkLite
import Cordova

class ViewController: CDVViewController, WKNavigationDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()

        var userContentController = WKUserContentController()

        var config : WKWebViewConfiguration = WKWebViewConfiguration()
        config.userContentController = userContentController
        var webview = WKWebView(frame: view.frame, configuration: config)
        webview.autoresizingMask = UIViewAutoresizing.FlexibleWidth | UIViewAutoresizing.FlexibleHeight
        webview.frame = view.frame
        webview.navigationDelegate = self
        view.addSubview(webview)

        if NSBundle.mainBundle().objectForInfoDictionaryKey("CordovaPlugins") != nil {
            webview.loadExtension("xwalk.cordova", namespace: nil, parameter: nil)
        }

        if let path = NSBundle.mainBundle().pathForResource("index", ofType: "html", inDirectory:"www") {
            webview.loadRequest(NSURLRequest(URL: NSURL.fileURLWithPath(path)!));
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }


}

