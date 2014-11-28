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

- (id)call:(id)target {
    return [Invocation call:target method:method arguments:arguments];
}

+ (id)call:(id)target method:(SEL)method arguments:(NSArray *)args {
    NSMethodSignature *sig = [target methodSignatureForSelector:method];
    if (sig == nil) {
        [target doesNotRecognizeSelector:method];
        return nil;
    }

    NSInvocation *inv = [NSInvocation invocationWithMethodSignature:sig];
    [inv setSelector:method];

    for(int i = 0; i < args.count; ++i) {
        NSDictionary *pair = [args objectAtIndex:i];
        NSObject* val = [pair.allValues objectAtIndex:0];
        if (val.class == NSNull.class)
            val = nil;
        [inv setArgument:&val atIndex:(i + 2)];
    }
    if (args.count)
    [inv retainArguments];

    id result = nil;
    [inv invokeWithTarget:target];
    if (sizeof(id) == [sig methodReturnLength])
        [inv getReturnValue:&result];
    return result;
}

@end
