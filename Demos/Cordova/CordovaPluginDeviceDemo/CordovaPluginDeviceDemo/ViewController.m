// Copyright (c) 2014 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "ViewController.h"
#import <WebKit/WebKit.h>

@import XWalkView;

@interface ViewController () <WKNavigationDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    WKUserContentController* userContentController = [[WKUserContentController alloc] init];
    WKWebViewConfiguration* config = [[WKWebViewConfiguration alloc] init];
    config.userContentController = userContentController;
    WKWebView* webview = [[WKWebView alloc] initWithFrame:self.view.frame configuration:config];

    webview.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    webview.frame = self.view.frame;
    webview.navigationDelegate = self;
    [self.view addSubview:webview];

    if ([[NSBundle mainBundle] objectForInfoDictionaryKey:@"CordovaPlugins"]) {
        id ext = [XWalkExtensionFactory createExtension:@"xwalk.cordova"];
        [webview loadExtension:ext namespace:@"" thread:[NSThread mainThread]];
    }
    NSString* path = [[NSBundle mainBundle] pathForResource:@"index" ofType:@"html" inDirectory:@"www"];
    if (path.length) {
        [webview loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:path]]];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
