// Copyright (c) 2014 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <objc/objc-runtime.h>
#import <Foundation/Foundation.h>

#import "Invocation.h"
#import "XWalkExtension.h"
#import "XWalkView/XWalkView-Swift.h"

static id wrapper_method(id self, SEL _cmd, ...) {
    NSString *sel = [NSString stringWithFormat:@"_%@", NSStringFromSelector(_cmd)];
    va_list ap;
    va_start(ap, _cmd);
    ReturnValue *result = [Invocation call:self selector:NSSelectorFromString(sel) valist:ap];
    va_end(ap);
    if (!result.isBool)
        [NSException raise:@"TypeError" format:@"Native method must return a boolean value."];

    if (result.boolValue) {
        NSMethodSignature *sig = [self methodSignatureForSelector:_cmd];
        UInt32 callid;
        va_start(ap, _cmd);
        if (!strcmp([sig getArgumentTypeAtIndex: 2], @encode(id))) {
            callid = va_arg(ap, NSNumber*).unsignedIntValue;
        } else {
            callid = va_arg(ap, UInt32);
        }
        va_end(ap);
        [(XWalkExtension *)self releaseArguments:callid];
    }
    return nil;
}

static void wrapper_setter(id self, SEL _cmd, id value)
{
    NSString *sel = NSStringFromSelector(_cmd);

    // Update javascript property firstly
    NSString *name = [sel substringWithRange: NSMakeRange(10, sel.length - 11)];
    [(XWalkExtension *)self setProperty:name value:value];

    // Update native property
    sel = [NSString stringWithFormat:@"_%@", sel];
    ((void (*)(id, SEL, id))objc_msgSend)(self, NSSelectorFromString(sel), value);
}

IMP xwalkExtensionMethod = (IMP)wrapper_method;
IMP xwalkExtensionSetter = (IMP)wrapper_setter;
