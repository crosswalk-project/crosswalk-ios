// Copyright (c) 2015 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "XWalkCordovaExtension.h"

#import <WebKit/WebKit.h>
#import "CDVCommandDelegate.h"
#import "CDVCommandQueue.h"
#import "CDVPlugin.h"
#import "CDVUserAgentUtil.h"
#import "CDVViewController.h"
#import "XWalkWebViewEngine.h"

@interface XWalkCordovaExtension () <CDVCommandDelegate>

@property(nonatomic) NSMutableDictionary* plugins;
@property(nonatomic) CDVCommandQueue* commandQueue;
@property(nonatomic) NSRegularExpression* callbackIdPattern;
@property(nonatomic) XWalkWebViewEngine* engine;
@property(nonatomic) NSString* userAgent;

@property(nonatomic, weak) CDVViewController* controller;

- (void)didBindExtension:(XWalkChannel*)channel instance:(NSInteger)instance;
- (void)scanForPlugins;
- (void)registerPlugin:(CDVPlugin*)plugin className:(NSString*)className;
- (BOOL)jsfunc_postToNative:(UInt32)cid message:(NSString*)message;
- (BOOL)isValidCallbackId:(NSString*)callbackId;

 /// CDVCommandDelegate
- (NSString*)pathForResource:(NSString*)resourcepath;
- (id)getCommandInstance:(NSString*)pluginName;
- (void)sendPluginResult:(CDVPluginResult*)result callbackId:(NSString*)callbackId;
- (void)evalJs:(NSString*)js;
- (void)evalJs:(NSString*)js scheduledOnRunLoop:(BOOL)scheduledOnRunLoop;
- (void)runInBackground:(void (^)())block;
- (NSString*)userAgent;
- (BOOL)URLIsWhitelisted:(NSURL*)url;

@end

@implementation XWalkCordovaExtension

@synthesize urlTransformer;

- (id)initWithViewController:(CDVViewController*)controller {
    if (self = [super init]) {
        _controller = controller;
        self.plugins = [[NSMutableDictionary alloc] init];
        NSError* err = nil;
        self.callbackIdPattern = [NSRegularExpression regularExpressionWithPattern:@"[^A-Za-z0-9._-]" options:0 error:&err];
        if (err != nil) {
            // Couldn't initialize Regex
            NSLog(@"Error: Couldn't initialize regex");
            self.callbackIdPattern = nil;
        }
        self.commandQueue = [[CDVCommandQueue alloc] initWithViewController:controller];
        controller.commandDelegate = self;
    }
    return self;
}

- (void)dealloc {
    [[self.plugins allValues] makeObjectsPerformSelector:@selector(dispose)];
}

- (void)didBindExtension:(XWalkChannel*)channel instance:(NSInteger)instance {
    [super didBindExtension:channel instance:instance];
    self.engine = [[XWalkWebViewEngine alloc] initWithWebView:channel.webView];
    [self scanForPlugins];
}

- (NSDictionary*)settings {
    return _controller ? _controller.settings : nil;
}

- (void)scanForPlugins {
    NSArray* pluginInfoArray = self.settings[@"cordova_plugins"];
    if (!pluginInfoArray) {
        NSLog(@"Failed to parse cordova plugin info.");
        return;
    }
    for (NSDictionary* pluginInfo in pluginInfoArray) {
        Class class = NSClassFromString(pluginInfo[@"class"]);
        SEL init = @selector(initWithWebViewEngine:);
        CDVPlugin* plugin = [XWalkInvocation construct:class initializer:init, self.engine];
        if (!plugin) {
            NSLog(@"Failed to create plugin with class name:%@", pluginInfo[@"class"]);
            continue;
        }
        [self registerPlugin:plugin className:pluginInfo[@"name"]];
    }
}

- (void)registerPlugin:(CDVPlugin*)plugin className:(NSString*)className {
    plugin.viewController = _controller;
    plugin.commandDelegate = self;
    self.plugins[[className lowercaseString]] = plugin;
    [plugin pluginInitialize];
}

- (BOOL)jsfunc_postToNative:(UInt32)cid message:(NSString*)message {
    if (message.length == 0) {
        return NO;
    }
    [self.commandQueue enqueueCommandBatch:message];
    [self.commandQueue executePending];
    return YES;
}

- (BOOL)isValidCallbackId:(NSString*)callbackId {
    if (!callbackId || !self.callbackIdPattern) {
        return NO;
    }

    // Disallow if too long or if any invalid characters were found.
    if (callbackId.length > 100
    || [self.callbackIdPattern firstMatchInString:callbackId options:0 range:NSMakeRange(0, callbackId.length)]) {
        return NO;
    }
    return YES;
}

/// CDVCommandDelegate Impl
- (NSString*)pathForResource:(NSString*)resourcepath {
    // TODO: (jondong) To be implemented when needed
    return @"";
}

- (id)getCommandInstance:(NSString*)pluginName {
    CDVPlugin* plugin = self.plugins[[pluginName lowercaseString]];
    if (!plugin) {
      NSLog(@"Failed to find registered plugin by class name:%@", pluginName);
      return nil;
    }
    return plugin;
}

- (void)sendPluginResult:(CDVPluginResult*)result callbackId:(NSString*)callbackId {
    // This occurs when there is are no win/fail callbacks for the call.
    if ([@"INVALID" isEqualToString : callbackId]) {
        return;
    }
    // This occurs when the callback id is malformed.
    if (![self isValidCallbackId:callbackId]) {
        NSLog(@"Invalid callback id received by sendPluginResult");
        return;
    }
    int status = [result.status intValue];
    BOOL keepCallback = [result.keepCallback boolValue];
    NSString* argumentsAsJSON = [result argumentsAsJSON];

    NSString* js = [NSString stringWithFormat:@"cordova.require('cordova/exec').nativeCallback('%@',%d,%@,%d)", callbackId, status, argumentsAsJSON, keepCallback];

    [self.channel evaluateJavaScript:js completionHandler:nil];
}

- (void)evalJs:(NSString*)js {
    [self evalJs:js scheduledOnRunLoop:YES];
}

- (void)evalJs:(NSString*)js scheduledOnRunLoop:(BOOL)scheduledOnRunLoop {
    NSString* message = [NSString stringWithFormat:@"cordova.require('cordova/exec').nativeEvalAndFetch(function(){%@})", js];
    [self.channel evaluateJavaScript:message completionHandler:nil];
}

- (void)runInBackground:(void (^)())block {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), block);
}

- (NSString*)userAgent {
    if (_userAgent == nil) {
        NSString* localBaseUserAgent = [CDVUserAgentUtil originalUserAgent];
        // Use our address as a unique number to append to the User-Agent.
        _userAgent = [NSString stringWithFormat:@"%@ (%lld)", localBaseUserAgent, (long long)self];
    }
    return _userAgent;
}

- (BOOL)URLIsWhitelisted:(NSURL*)url {
    // TODO: (jondong) To be implemented when needed
    return YES;
}

@end
