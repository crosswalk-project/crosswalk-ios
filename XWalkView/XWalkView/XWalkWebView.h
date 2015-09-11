// Copyright (c) 2015 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <WebKit/WebKit.h>

@interface XWalkView : WKWebView

- (void)loadExtension:(NSObject*)object namespace:(NSString*)ns;
- (WKUserScript*)injectScript:(NSString*)code;
- (WKNavigation*)loadFileURL:(NSURL*)URL allowingReadAccessToURL:(NSURL*)readAccessURL;

@end

@interface WKUserContentController (XWalkView)
    - (void)removeUserScript:(WKUserScript*)script;
@end