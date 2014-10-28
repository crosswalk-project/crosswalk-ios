// Copyright (c) 2014 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "Invocation.h"

@implementation Invocation

- (id)initWithMethod:(NSString *)name arguments:(NSArray *)args {
    NSMutableString *str = [NSMutableString string];
    [str appendString:name];
    if (args.count > 0)
        [str appendString:@":"];
    for (int i = 1; i < args.count; ++i) {
        NSDictionary *pair = [args objectAtIndex:i];
        [str appendString:[pair.allKeys objectAtIndex:0]];
        [str appendString:@":"];
    }
    NSLog(@"method: %@", str);
    method = NSSelectorFromString(str);
    arguments = args;
    return self;
}

- (void)call:(id)target {
    [Invocation call:target method:method arguments:arguments];
}

+ (void)call:(id)target method:(SEL)method arguments:(NSArray *)args {
    NSMethodSignature *sig = [target methodSignatureForSelector:method];
    NSInvocation *inv = [NSInvocation invocationWithMethodSignature:sig];
    [inv setTarget:target];
    [inv setSelector:method];
    for(int i = 0; i < args.count; ++i) {
        NSDictionary *pair = [args objectAtIndex:i];
        id val = [pair.allValues objectAtIndex:0];
        [inv setArgument:&val atIndex:(i + 2)];
    }
    [inv retainArguments];
    [inv invoke];
}

@end