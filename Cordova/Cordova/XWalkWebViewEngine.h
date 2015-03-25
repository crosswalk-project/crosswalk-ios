// Copyright (c) 2015 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "CDVWebViewEngineProtocol.h"
@class WKWebView;

@interface XWalkWebViewEngine : NSObject<CDVWebViewEngineProtocol>

- (id)initWithWebView:(WKWebView*)webview;

// CDVWebViewEngineProtocol Impl
@property (nonatomic, strong, readonly) UIView* engineWebView;

- (id)loadRequest:(NSURLRequest*)request;
- (id)loadHTMLString:(NSString*)string baseURL:(NSURL*)baseURL;
- (void)evaluateJavaScript:(NSString*)javaScriptString completionHandler:(void (^)(id, NSError*))completionHandler;

- (NSURL*)URL;

- (instancetype)initWithFrame:(CGRect)frame;
- (void)updateWithInfo:(NSDictionary*)info;

@end
