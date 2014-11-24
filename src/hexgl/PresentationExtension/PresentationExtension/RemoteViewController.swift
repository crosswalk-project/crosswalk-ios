//
//  RemoteViewController.swift
//  PresentationExtension
//
//  Created by Jonathan Dong on 11/13/14.
//  Copyright (c) 2014 Crosswalk. All rights reserved.
//

import Foundation
import CrosswalkLite
import WebKit

class RemoteViewController: UIViewController, WKNavigationDelegate {
    var webview: WKWebView?
    var messages: Array<String> = []

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

        self.webview = webview
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func loadURL(url: NSURL) {
        webview?.loadRequest(NSURLRequest(URL: url))
    }

    func loadExtension(name: String) {
        webview?.loadExtension(name)
    }

    func sendMessage(message: String) {
        var jsCodes = "(function() {" +
                        "var e = document.createEvent('Event');" +
                        "e.initEvent('message', true, true);" +
                        "e.data = JSON.stringify(\(message));" +
                        "window.dispatchEvent(e);" +
                      "}())"
        if webview!.loading {
            messages.append(jsCodes)
        } else {
            evaluateJavaScript(jsCodes)
        }
    }

    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        for jsCodes in messages {
            evaluateJavaScript(jsCodes)
        }
        messages.removeAll()
    }

    private func evaluateJavaScript(jsCodes: String) {
        webview?.evaluateJavaScript(jsCodes, completionHandler: { (obj, error) -> Void in
            if error != nil {
                println("Failed to inject script: \(jsCodes), with error: \(error)")
            }
        })
    }
}