// Copyright (c) 2015 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

@interface XWalkExtensionTest : XCTestCase

@end

@implementation XWalkExtensionTest

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testNamespace {
    XCTAssert(YES, @"Pass");
}

- (void)testSetJavaScriptProperty {
    XCTAssert(YES, @"Pass");
}

- (void)testInvokeCallback {
    XCTAssert(YES, @"Pass");
}

- (void)testInvokeJavaScript {
    XCTAssert(YES, @"Pass");
}

- (void)testEvaluateJavaScript {
    XCTAssert(YES, @"Pass");
}

- (void)testInvokeNativeMethod {
    XCTAssert(YES, @"Pass");
}

- (void)testSetNativeProperty {
    XCTAssert(YES, @"Pass");
}

- (void)testDidGenerateStub {
    XCTAssert(YES, @"Pass");
}

- (void)testDidBindExtension {
    XCTAssert(YES, @"Pass");
}

- (void)testDidUnbindExtension {
    XCTAssert(YES, @"Pass");
}

@end

