// Copyright (c) 2015 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "XWalkInvocation.h"

@interface DemoClass : NSObject
@property(nonatomic, copy) NSString* name;

- (id)initWithName:(NSString*)name;
- (void)asyncMethod:(XCTestExpectation*)expectation;

@end

@implementation DemoClass

- (id)initWithName:(NSString *)name {
    if (self = [super init]) {
        _name = name;
    }
    return self;
}

- (NSString*)getName {
    return _name;
}

- (void)asyncMethod:(XCTestExpectation*)expectation {
    [expectation fulfill];
}

@end

@interface XWalkInvocationTest : XCTestCase
@property(nonatomic, strong) DemoClass* demo;

@end

@implementation XWalkInvocationTest

- (void)setUp {
    [super setUp];
    self.demo = [[DemoClass alloc] initWithName:@"DemoObject"];
}

- (void)tearDown {
    [super tearDown];
    self.demo = nil;
}

- (void)testConstruct {
    XCTAssertNotNil([XWalkInvocation construct:DemoClass.class initializer:NSSelectorFromString(@"initWithName:") arguments:@[@"AnotherDemoObject"]]);
}

- (void)testCall {
    NSValue* value = [XWalkInvocation call:self.demo selector:NSSelectorFromString(@"getName") arguments:nil];
    NSString* name = [NSString stringWithFormat:@"%@", [value pointerValue]];
    XCTAssertEqualObjects(@"DemoObject", name);
}

- (void)testAsyncCall {
    XCTestExpectation *expectation = [self expectationWithDescription:@"AsyncCall"];
    [XWalkInvocation asyncCall:self.demo selector:NSSelectorFromString(@"asyncMethod:"), expectation];
    [self waitForExpectationsWithTimeout:0.1 handler:^(NSError* error) {
        if (error) {
            XCTAssert(NO, @"testAsyncCall failed");
        }
    }];
}

@end
