// Copyright (c) 2015 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "XWalkWebViewEngine.h"

#import <WebKit/WebKit.h>

@interface XWalkWebViewEngine() {
    WKWebView* _engineWebView;
}
@end

@implementation XWalkWebViewEngine

- (id)initWithWebView:(WKWebView*)webview {
    if (self = [super init]) {
        _engineWebView = webview;
    }
    return self;
}

- (id)loadRequest:(NSURLRequest*)request {
    return [_engineWebView loadRequest:request];
}

- (id)loadHTMLString:(NSString*)string baseURL:(NSURL*)baseURL {
    return [_engineWebView loadHTMLString:string baseURL:baseURL];
}

- (void)evaluateJavaScript:(NSString*)javaScriptString completionHandler:(void (^)(id, NSError*))completionHandler {
    [_engineWebView evaluateJavaScript:javaScriptString completionHandler:completionHandler];
}

- (NSURL*)URL {
    return _engineWebView.URL;
}

- (instancetype)initWithFrame:(CGRect)frame {
    [NSException raise:@"InitError" format:@"initWithFrame: of XWalkWebViewEngine should not be used, use initWithWebView: instead."];
    return nil;
}

- (void)updateWithInfo:(NSDictionary*)info {
    // TODO(jondong): To be implemented.
}

@end
