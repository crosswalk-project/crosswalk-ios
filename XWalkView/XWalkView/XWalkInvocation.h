// Copyright (c) 2014 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>

@interface NSValue (XWalkInvocation)

@property (nonatomic, readonly) BOOL isNumber;
@property (nonatomic, readonly) BOOL isObject;
@property (nonatomic, readonly) BOOL isVoid;

+ (NSValue *)valueWithInvocation:(NSInvocation *)invocation;

@end

@interface XWalkInvocation : NSObject

+ (id)construct:(Class)aClass initializer:(SEL)selector arguments:(NSArray *)args;
+ (id)constructOnThread:(NSThread *)thread class:(Class)aClass initializer:(SEL)selector arguments:(NSArray *)args;

+ (NSValue *)call:(id)target selector:(SEL)selector arguments:(NSArray *)args;
+ (NSValue *)callOnThread:(NSThread *)thread target:(id)target selector:(SEL)selector arguments:(NSArray *)args;

+ (void)asyncCall:(id)target selector:(SEL)selector arguments:(NSArray *)args;
+ (void)asyncCallOnThread:(NSThread *)thread target:(id)target selector:(SEL)selector arguments:(NSArray *)args;

// Variadic methods

+ (id)construct:(Class)aClass initializer:(SEL)selector, ...;
+ (id)constructOnThread:(NSThread *)thread class:(Class)aClass initializer:(SEL)selector, ...;

+ (NSValue *)call:(id)target selector:(SEL)selector, ...;
+ (NSValue *)callOnThread:(NSThread *)thread target:(id)target selector:(SEL)selector, ...;

+ (void)asyncCall:(id)target selector:(SEL)selector, ...;
+ (void)asyncCallOnThread:(NSThread *)thread target:(id)target selector:(SEL)selector, ...;

@end
