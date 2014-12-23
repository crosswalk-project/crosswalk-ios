/*
 Licensed to the Apache Software Foundation (ASF) under one
 or more contributor license agreements.  See the NOTICE file
 distributed with this work for additional information
 regarding copyright ownership.  The ASF licenses this file
 to you under the Apache License, Version 2.0 (the
 "License"); you may not use this file except in compliance
 with the License.  You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing,
 software distributed under the License is distributed on an
 "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 KIND, either express or implied.  See the License for the
 specific language governing permissions and limitations
 under the License.
 */

#import <Foundation/Foundation.h>
#import "CDVPlugin.h"

NSString* const CDVPageDidLoadNotification = @"CDVPageDidLoadNotification";
NSString* const CDVPluginHandleOpenURLNotification = @"CDVPluginHandleOpenURLNotification";
NSString* const CDVPluginResetNotification = @"CDVPluginResetNotification";
NSString* const CDVLocalNotification = @"CDVLocalNotification";
NSString* const CDVRemoteNotification = @"CDVRemoteNotification";
NSString* const CDVRemoteNotificationError = @"CDVRemoteNotificationError";

@interface CDVPlugin ()

@end

@implementation CDVPlugin

- (CDVPlugin*)initWithWebView:(UIWebView*)theWebView
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppTerminate) name:UIApplicationWillTerminateNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMemoryWarning) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleOpenURL:) name:CDVPluginHandleOpenURLNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onReset) name:CDVPluginResetNotification object:theWebView];

        self.webView = theWebView;
    }
    return self;
}

- (void)pluginInitialize {
}

/* NOTE: calls into JavaScript must not call or trigger any blocking UI, like alerts */
- (void)handleOpenURL:(NSNotification*)notification
{
    // override to handle urls sent to your app
    // register your url schemes in your App-Info.plist

    NSURL* url = [notification object];

    if ([url isKindOfClass:[NSURL class]]) {
        /* Do your thing! */
    }
}

/* NOTE: calls into JavaScript must not call or trigger any blocking UI, like alerts */
- (void)onAppTerminate
{
    // override this if you need to do any cleanup on app exit
}

- (void)onMemoryWarning
{
    // override to remove caches, etc
}

- (void)onReset
{
    // Override to cancel any long-running requests when the WebView navigates or refreshes.
}

@end
