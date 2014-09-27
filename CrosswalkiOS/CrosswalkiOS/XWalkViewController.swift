//
//  XWalkViewController.swift
//  CrosswalkiOS
//
//  Created by Jonathan Dong on 14/9/24.
//  Copyright (c) 2014年 Crosswalk. All rights reserved.
//

import UIKit
import WebKit

public class XWalkViewController: UIViewController, WKNavigationDelegate, XWalkExtensionManagerDelegate {
    var webview : WKWebView?
    var userContentController : WKUserContentController?
    var extensionManager : XWalkExtensionManager?

    override public func viewDidLoad() {
        super.viewDidLoad()

        userContentController = WKUserContentController()

        var config : WKWebViewConfiguration = WKWebViewConfiguration()
        config.userContentController = userContentController
        var webview = WKWebView(frame: view.frame, configuration: config)
        webview.autoresizingMask = UIViewAutoresizing.FlexibleWidth | UIViewAutoresizing.FlexibleHeight
        webview.frame = view.frame
        webview.navigationDelegate = self
        view.addSubview(webview)
        self.webview = webview

        extensionManager = XWalkExtensionManager()
        extensionManager?.contentController = userContentController
        extensionManager?.delegate = self
    }

    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        webview = nil
        extensionManager = nil
        userContentController = nil
    }

    public func loadExtensionsByBundleNames(names: [String]) {
        extensionManager?.loadExtensionsByBundleNames(names)
    }

    public func loadURL(url: NSURL) {
        webview?.loadRequest(NSURLRequest(URL: url));
    }

    func onPostMessageToJS(message: String) {
        let script = "messageListener(\"\(message)\");"
        webview?.evaluateJavaScript(script, completionHandler: { (object, error) -> Void in
            if error != nil {
                println("Failed to execute script, with error:\(error)")
            }
        })
    }
}
