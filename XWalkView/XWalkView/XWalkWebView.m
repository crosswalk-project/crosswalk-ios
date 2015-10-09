// Copyright (c) 2015 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


#import "XWalkWebView.h"

#import <GCDWebServer/GCDWebServer.h>
#import "XWalkView/XWalkView-Swift.h"

@interface XWalkView ()

@property(nonatomic, strong) XWalkThread* extensionThread;
@property(nonatomic, strong) NSMutableDictionary* channels;

@end

@implementation XWalkView

+ (GCDWebServer*)httpServer
{
    static dispatch_once_t once;
    static GCDWebServer* server = nil;
    if (!server) {
        dispatch_once(&once, ^{
            server = [[GCDWebServer alloc] init];
        });
    }
    return server;
}

- (void)dealloc
{
    for (XWalkChannel* channel in [self.channels allValues]) {
        [channel destroyExtension];
    }
}

- (void)loadExtension:(NSObject*)object namespace:(NSString*)ns
{
    if (!self.channels) {
        self.channels = [NSMutableDictionary dictionary];
    }

    if (!self.extensionThread) {
        [self prepareForExtension];
        self.extensionThread = [[XWalkThread alloc] init];
        [self.extensionThread start];
    }

    XWalkChannel* channel = [[XWalkChannel alloc] initWithWebView:self];
    [channel bind:object namespace:ns thread:self.extensionThread];
    NSAssert(self.channels[channel.name] == nil, @"Duplicate channel name:", channel.name);
    self.channels[channel.name] = channel;
}

- (void)prepareForExtension
{
    NSBundle* bundle = [NSBundle bundleForClass:self.class];
    NSAssert(bundle, @"Failed to load bundle for class:", self.description);
    if (!bundle) {
        return;
    }

    NSString* path = [bundle pathForResource:@"crosswalk" ofType:@"js"];
    if (path) {
        NSString* code = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
        if (code) {
            [self injectScript:code];
        } else {
            [NSException raise:@"EncodingError" format:@"'%@.js' should be UTF-8 encoding.", path];
        }
    }
}

- (WKUserScript*)injectScript:(NSString*)code
{
    WKUserScript* script = [[WKUserScript alloc] initWithSource:code injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:false];
    [self.configuration.userContentController addUserScript:script];
    if (self.URL) {
        [self evaluateJavaScript:code completionHandler:^(id object, NSError *error) {
            if (error) {
                NSLog(@"ERROR: Failed to inject JavaScript API.\n%@", error);
            }
        }];
    }
    return script;
}

- (WKNavigation*)loadFileURL:(NSURL*)URL allowingReadAccessToURL:(NSURL*)readAccessURL
{
    if ([self.superclass instancesRespondToSelector:NSSelectorFromString(@"loadFileURL:allowingReadAccessToURL:")]) {
        return [super loadFileURL:URL allowingReadAccessToURL:readAccessURL];
    }

    // The implementation with embedding HTTP server for iOS 8 deployment.
    if (!URL.fileURL || !readAccessURL.fileURL) {
        NSURL* url = URL.fileURL ? readAccessURL : URL;
        [NSException raise:NSInvalidArgumentException format:@"%@ is not a file URL", url];
    }

    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSURLRelationship relationship = NSURLRelationshipOther;
    BOOL isDictionary = NO;
    if (![fileManager fileExistsAtPath:readAccessURL.path isDirectory:&isDictionary] || !isDictionary
        || ![fileManager getRelationship:&relationship ofDirectoryAtURL:readAccessURL toItemAtURL:URL error:nil]
        || relationship == NSURLRelationshipOther) {
        return nil;
    }

    NSUInteger port = 8080;
    if (![XWalkView httpServer].isRunning) {
        [[XWalkView httpServer] addGETHandlerForBasePath:@"/" directoryPath:readAccessURL.path indexFilename:nil cacheAge:3600 allowRangeRequests:YES];
        [[XWalkView httpServer] startWithPort:port bonjourName:nil];
    }

    NSString* target = [URL.path substringFromIndex:readAccessURL.path.length];
    NSURLComponents* components = [[NSURLComponents alloc] initWithString:@"http://127.0.0.1"];
    components.port = [NSNumber numberWithUnsignedInteger:port];
    components.path = target;
    return [self loadRequest:[NSURLRequest requestWithURL:components.URL]];
}

@end

@implementation WKUserContentController (XWalkView)

- (void)removeUserScript:(WKUserScript*)script
{
    NSArray* scripts = self.userScripts;
    [self removeAllUserScripts];
    for (WKUserScript* i in scripts) {
        if (i != script) {
            [self addUserScript:i];
        }
    }
}

@end