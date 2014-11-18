//
//  ViewController.swift
//  HexGLApp
//
//  Created by Jonathan Dong on 11/6/14.
//  Copyright (c) 2014 Crosswalk. All rights reserved.
//

import UIKit
import CrosswalkLite
import WebKit

class ViewController: UIViewController, WKNavigationDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()

        var userContentController = WKUserContentController()

        var config : WKWebViewConfiguration = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaPlaybackRequiresUserAction = false
        config.userContentController = userContentController
        var webview = WKWebView(frame: view.frame, configuration: config, script: nil)
        webview.autoresizingMask = UIViewAutoresizing.FlexibleWidth | UIViewAutoresizing.FlexibleHeight
        webview.frame = view.frame
        webview.navigationDelegate = self
        view.addSubview(webview)

        webview.loadExtension("navigator.presentation")

        var url: NSURL = NSURL(scheme: "http", host: "localhost:8080", path: "/index.html")!
        webview.loadRequest(NSURLRequest(URL: url))
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

