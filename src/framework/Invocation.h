// Copyright (c) 2014 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/*
 Be sure to import this file in your project's bridging header file.
 #import "Invocation.h"
 */

@import Foundation;

/* TODO: define an ordered dictionary class for arguments */

@interface Invocation : NSObject
{
    SEL method;
    NSArray *arguments;
}

- (id)initWithMethod:(NSString *)method arguments:(NSArray *)arg;

- (id)call:(id)target;

+ (id)call:(id)target method:(SEL)method arguments:(NSArray *)arg;

@end
