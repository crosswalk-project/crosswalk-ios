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

#import "CDVViewController.h"

#import "CDVCommandDelegate.h"
#import "CDVPlugin.h"
#import "CDVURLProtocol.h"
#import "CDVUserAgentUtil.h"

@interface CDVViewController () {
    NSString* _userAgent;
}
@property (nonatomic, readwrite, strong) CDVWhitelist* whitelist;
@property (nonatomic, readwrite, strong) NSArray* supportedOrientations;

@property (assign) BOOL initialized;
@property (atomic, assign) NSInteger userAgentLockToken;
@end

@implementation CDVViewController

- (void)__init {
    if ((self != nil) && !self.initialized) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppWillTerminate:)
                                                     name:UIApplicationWillTerminateNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppWillResignActive:)
                                                     name:UIApplicationWillResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppDidBecomeActive:)
                                                     name:UIApplicationDidBecomeActiveNotification object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppWillEnterForeground:)
                                                     name:UIApplicationWillEnterForegroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppDidEnterBackground:)
                                                     name:UIApplicationDidEnterBackgroundNotification object:nil];

        // read from UISupportedInterfaceOrientations (or UISupportedInterfaceOrientations~iPad, if its iPad) from -Info.plist
        self.supportedOrientations = [self parseInterfaceOrientations:
                                      [[[NSBundle mainBundle] infoDictionary] objectForKey:@"UISupportedInterfaceOrientations"]];

        self.initialized = YES;

        [self loadSettings];
    }
}

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    [self __init];
    return self;
}

- (id)initWithCoder:(NSCoder*)aDecoder
{
    self = [super initWithCoder:aDecoder];
    [self __init];
    return self;
}

- (id)init
{
    self = [super init];
    [self __init];
    return self;
}

- (void)dealloc
{
    [CDVUserAgentUtil releaseLock:&_userAgentLockToken];
    [CDVURLProtocol unregisterViewController:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)loadSettings {
    NSString* plistPath = [NSBundle.mainBundle pathForResource:@"manifest" ofType:@"plist"];
    if (!plistPath) {
        NSLog(@"Failed to find manifest.plist in main bundle.");
        return;
    }
    _settings = [[NSMutableDictionary alloc] initWithDictionary:[NSDictionary dictionaryWithContentsOfFile:plistPath]];
}

- (CDVWhitelist*)whitelist {
    if (_whitelist == nil) {
        id object = self.settings[@"cordova_access"];
        NSArray* accessArray = nil;
        if (object && [object isKindOfClass:[NSArray class]]) {
            accessArray = (NSArray*)object;
        } else {
            accessArray = @[];
        }
        _whitelist = [[CDVWhitelist alloc] initWithArray:object];
    }
    return _whitelist;
}

- (BOOL)URLisAllowed:(NSURL*)url {
    return [self.whitelist URLIsAllowed:url];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [CDVURLProtocol registerViewController:self];

    [CDVUserAgentUtil acquireLock:^(NSInteger lockToken) {
        self.userAgentLockToken = lockToken;
        [CDVUserAgentUtil setUserAgent:self.userAgent lockToken:lockToken];
    }];
}

- (NSArray*)parseInterfaceOrientations:(NSArray*)orientations
{
    NSMutableArray* result = [[NSMutableArray alloc] init];

    if (orientations != nil) {
        NSEnumerator* enumerator = [orientations objectEnumerator];
        NSString* orientationString;

        while (orientationString = [enumerator nextObject]) {
            if ([orientationString isEqualToString:@"UIInterfaceOrientationPortrait"]) {
                [result addObject:[NSNumber numberWithInt:UIInterfaceOrientationPortrait]];
            } else if ([orientationString isEqualToString:@"UIInterfaceOrientationPortraitUpsideDown"]) {
                [result addObject:[NSNumber numberWithInt:UIInterfaceOrientationPortraitUpsideDown]];
            } else if ([orientationString isEqualToString:@"UIInterfaceOrientationLandscapeLeft"]) {
                [result addObject:[NSNumber numberWithInt:UIInterfaceOrientationLandscapeLeft]];
            } else if ([orientationString isEqualToString:@"UIInterfaceOrientationLandscapeRight"]) {
                [result addObject:[NSNumber numberWithInt:UIInterfaceOrientationLandscapeRight]];
            }
        }
    }

    // default
    if ([result count] == 0) {
        [result addObject:[NSNumber numberWithInt:UIInterfaceOrientationPortrait]];
    }

    return result;
}

- (NSInteger)mapIosOrientationToJsOrientation:(UIInterfaceOrientation)orientation
{
    switch (orientation) {
        case UIInterfaceOrientationPortraitUpsideDown:
            return 180;
        case UIInterfaceOrientationLandscapeLeft:
            return -90;
        case UIInterfaceOrientationLandscapeRight:
            return 90;
        case UIInterfaceOrientationPortrait:
            return 0;
        default:
            return 0;
    }
}

- (NSUInteger)supportedInterfaceOrientations {
    NSUInteger ret = 0;

    if ([self shouldAutorotateToInterfaceOrientation:UIInterfaceOrientationPortrait]) {
        ret = ret | (1 << UIInterfaceOrientationPortrait);
    }
    if ([self shouldAutorotateToInterfaceOrientation:UIInterfaceOrientationPortraitUpsideDown]) {
        ret = ret | (1 << UIInterfaceOrientationPortraitUpsideDown);
    }
    if ([self shouldAutorotateToInterfaceOrientation:UIInterfaceOrientationLandscapeRight]) {
        ret = ret | (1 << UIInterfaceOrientationLandscapeRight);
    }
    if ([self shouldAutorotateToInterfaceOrientation:UIInterfaceOrientationLandscapeLeft]) {
        ret = ret | (1 << UIInterfaceOrientationLandscapeLeft);
    }

    return ret;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation {
    return [self.supportedOrientations containsObject:[NSNumber numberWithInt:orientation]];
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (NSString*)userAgent {
    if (_userAgent == nil) {
        NSString* localBaseUserAgent;
        if (self.baseUserAgent) {
            localBaseUserAgent = self.baseUserAgent;
        } else {
            localBaseUserAgent = [CDVUserAgentUtil originalUserAgent];
        }
        _userAgent = [NSString stringWithFormat:@"%@ (%lld)", localBaseUserAgent, (long long)self];
    }
    return _userAgent;
}

#pragma mark WKWebViewDelegate

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    NSLog(@"Resetting plugins due to page load.");
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:CDVPluginResetNotification object:webView]];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    NSLog(@"Finished load of: %@", webView.URL);
    [CDVUserAgentUtil releaseLock:&_userAgentLockToken];

    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];

    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:CDVPageDidLoadNotification object:webView]];
}

- (void)printErrorMessage:(NSError*)error {
    NSString* message = [NSString stringWithFormat:@"Failed to load webpage with error: %@", [error localizedDescription]];
    NSLog(@"%@", message);
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    [CDVUserAgentUtil releaseLock:&_userAgentLockToken];
    [self printErrorMessage:error];
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    [CDVUserAgentUtil releaseLock:&_userAgentLockToken];
    [self printErrorMessage:error];
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {

    NSURL* url = navigationAction.request.URL;
    WKNavigationActionPolicy policy = WKNavigationActionPolicyCancel;

    /*
     * If a URL is being loaded that's a file/http/https URL, just load it internally
     */
    if ([url isFileURL]) {
        policy = WKNavigationActionPolicyAllow;
    }

    /*
     * all tel: scheme urls we let the UIWebview handle it using the default behavior
     */
    else if ([[url scheme] isEqualToString:@"tel"]) {
        policy = WKNavigationActionPolicyAllow;
    }

    /*
     * all about: scheme urls are not handled
     */
    else if ([[url scheme] isEqualToString:@"about"]) {
        policy = WKNavigationActionPolicyCancel;
    }

    /*
     * all data: scheme urls are handled
     */
    else if ([[url scheme] isEqualToString:@"data"]) {
        policy = WKNavigationActionPolicyAllow;
    }

    /*
     * Handle all other types of urls (tel:, sms:), and requests to load a url in the main webview.
     */
    else {
        if ([self.whitelist schemeIsAllowed:[url scheme]]) {
            if ([url.host isEqualToString:@"127.0.0.1"] || [url.host isEqualToString:@"localhost"]) {
                policy = WKNavigationActionPolicyAllow;
            } else {
                policy = [self.whitelist URLIsAllowed:url] ? WKNavigationActionPolicyAllow : WKNavigationActionPolicyCancel;
            }
        } else {
            if ([[UIApplication sharedApplication] canOpenURL:url]) {
                [[UIApplication sharedApplication] openURL:url];
            } else { // handle any custom schemes to plugins
                [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:CDVPluginHandleOpenURLNotification object:url]];
            }
            policy = WKNavigationActionPolicyCancel;
        }
    }
    decisionHandler(policy);
}

#pragma mark -
#pragma mark UIApplicationDelegate impl

- (void)onAppWillTerminate:(NSNotification*)notification
{
    // empty the tmp directory
    NSFileManager* fileMgr = [[NSFileManager alloc] init];
    NSError* __autoreleasing err = nil;

    // clear contents of NSTemporaryDirectory
    NSString* tempDirectoryPath = NSTemporaryDirectory();
    NSDirectoryEnumerator* directoryEnumerator = [fileMgr enumeratorAtPath:tempDirectoryPath];
    NSString* fileName = nil;
    BOOL result;

    while ((fileName = [directoryEnumerator nextObject])) {
        NSString* filePath = [tempDirectoryPath stringByAppendingPathComponent:fileName];
        result = [fileMgr removeItemAtPath:filePath error:&err];
        if (!result && err) {
            NSLog(@"Failed to delete: %@ (error: %@)", filePath, err);
        }
    }
}

- (void)onAppWillResignActive:(NSNotification*)notification
{
    [self.commandDelegate evalJs:@"cordova.fireDocumentEvent('resign');" scheduledOnRunLoop:NO];
}

- (void)onAppWillEnterForeground:(NSNotification*)notification
{
    [self.commandDelegate evalJs:@"cordova.fireDocumentEvent('resume');"];
}

// This method is called to let your application know that it moved from the inactive to active state.
- (void)onAppDidBecomeActive:(NSNotification*)notification
{
    [self.commandDelegate evalJs:@"cordova.fireDocumentEvent('active');"];
}

- (void)onAppDidEnterBackground:(NSNotification*)notification
{
    [self.commandDelegate evalJs:@"cordova.fireDocumentEvent('pause', null, true);" scheduledOnRunLoop:NO];
}

@end
