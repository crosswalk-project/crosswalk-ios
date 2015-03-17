// Copyright (c) 2015 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import <XCTest/XCTest.h>
#import "XWalkExtension.h"
#import "XWalkViewTests-Swift.h"
@import XWalkView;

@interface ExtensionTestExtension : XWalkExtension

@property(nonatomic, strong) NSNumber* jsprop_demoValue;

@property(nonatomic, copy) NSString* demoInvokeNativeMethodValue;

@property(nonatomic, strong) XCTestExpectation* didBindExpectation;
@property(nonatomic, strong) XCTestExpectation* didGenerateStubExpectation;

@end

@implementation ExtensionTestExtension

- (id)init {
    if (self = [super init]) {
        _jsprop_demoValue = [NSNumber numberWithInteger:3];
    }
    return self;
}

- (id)initFromJavaScript:(NSString*)script {
    if (self = [super init]) {
        _jsprop_demoValue = [NSNumber numberWithInteger:10];
    }
    return self;
}

- (void)jsfunc_demoFunction:(UInt32)callId  {
}

- (void)jsfunc_demoInvokeNativeMethod:(UInt32)callId value:(NSString*)value {
    self.demoInvokeNativeMethodValue = value;
}

- (NSString*)didGenerateStub:(NSString *)stub {
    if (self.didGenerateStubExpectation) {
        [self.didGenerateStubExpectation fulfill];
    }
    return stub;
}

- (void)didBindExtension:(XWalkChannel *)channel instance:(NSInteger)instance {
    [super didBindExtension:channel instance:instance];
    if (self.didBindExpectation) {
        [self.didBindExpectation fulfill];
    }
}

@end

@interface XWalkExtensionTest : XCTestCase <WKNavigationDelegate>

@property(nonatomic, strong) WKWebView* webview;
@property(nonatomic, copy) NSString* extensionName;
@property(nonatomic, strong) ExecutionContext* executionContext;
@property(nonatomic, strong) ExtensionTestExtension* ext;

@end

@implementation XWalkExtensionTest

- (void)setUp {
    [super setUp];
    self.extensionName = @"xwalk.test.ext";
    self.webview = [[WKWebView alloc] initWithFrame:CGRectZero configuration:[[WKWebViewConfiguration alloc] init]];
    self.webview.navigationDelegate = self;

    [XWalkExtensionFactory register:self.extensionName cls:[ExtensionTestExtension class]];

    self.ext = (ExtensionTestExtension*)[XWalkExtensionFactory createExtension:self.extensionName];
    [self.webview loadExtension:self.ext namespace:self.extensionName thread:nil];
}

- (void)tearDown {
    [super tearDown];
    self.webview = nil;
    self.ext = nil;
}

- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation {
    if (!self.executionContext) {
        return;
    }
    [self.webview evaluateJavaScript:self.executionContext.scriptToEvaluate completionHandler:^(id object, NSError *error) {
        if (self.executionContext.completionHandler) {
            self.executionContext.completionHandler(object, error);
        }
    }];
}

- (void)testNamespace {
    XCTAssertEqual(self.extensionName, self.ext.namespace);
}

- (void)testSetJavaScriptProperty {
    // TODO(jondong): Need to know the chance that the invocation has completed.
    XCTAssert(YES, @"Pass");
}

- (void)testInvokeCallback {
    // TODO(jondong): Need to know the chance that the invocation has completed.
    XCTAssert(YES, @"Pass");
}

- (void)testInvokeJavaScript {
    // TODO(jondong): Need to know the chance that the invocation has completed.
    XCTAssert(YES, @"Pass");
}

- (void)testEvaluateJavaScript {
    // TODO(jondong): Need to know the chance that the evaluation has completed.
    XCTAssert(YES, @"Pass");
}

- (void)testInvokeNativeMethod {
    NSString* newValue = @"newValue";
    [self.ext invokeNativeMethod:@"demoInvokeNativeMethod" arguments:@[@1, newValue]];
    XCTAssertEqual(self.ext.demoInvokeNativeMethodValue, newValue);
}

- (void)testSetNativeProperty {
    NSInteger newInteger = 111;
    [self.ext setNativeProperty:@"demoValue" value:[NSNumber numberWithInteger:newInteger]];
    XCTAssertEqual([self.ext.jsprop_demoValue integerValue], newInteger);
}

- (void)testDidGenerateStub {
    ExtensionTestExtension* ext = (ExtensionTestExtension*)[XWalkExtensionFactory createExtension:self.extensionName];
    ext.didGenerateStubExpectation = [self expectationWithDescription:@"DidGenerateStubExtension"];
    [self.webview loadExtension:ext namespace:self.extensionName thread:nil];

    [self waitForExpectationsWithTimeout:1 handler:^(NSError *error) {
        if (error) {
            XCTFail("testDidGenerateStub failed, with error:%@", error);
        }
    }];
}

- (void)testDidBindExtension {
    ExtensionTestExtension* ext = (ExtensionTestExtension*)[XWalkExtensionFactory createExtension:self.extensionName];
    ext.didBindExpectation = [self expectationWithDescription:@"DidBindExtension"];
    [self.webview loadExtension:ext namespace:self.extensionName thread:nil];

    [self waitForExpectationsWithTimeout:1 handler:^(NSError *error) {
        if (error) {
            XCTFail("testDidBindExtension failed, with error:%@", error);
        }
    }];
}

@end
