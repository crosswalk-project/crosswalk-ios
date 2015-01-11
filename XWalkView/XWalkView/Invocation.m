// Copyright (c) 2014 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <objc/runtime.h>

#import "Invocation.h"

@interface NSNumber (Invocation)
+ (NSNumber *)numberWithBytes:(const void *)value objCType:(const char *)type;
- (void)getValue:(void *)buffer objCType:(const char *)type;
@end


@implementation Invocation {
    NSString *name_;
    NSMutableString *selector_;
    NSMutableArray *arguments_;
}

- (id)initWithName:(NSString *)name {
    name_ = name;
    selector_ = [NSMutableString stringWithString:name];
    arguments_ = [NSMutableArray new];
    return self;
}

- (id)initWithName:(NSString *)name arguments:(NSArray *)args {
    self = [self initWithName:name];
    for (int i = 0; i < args.count; ++i) {
        NSDictionary *pair = [args objectAtIndex:i];
        NSString *key = [pair.allKeys objectAtIndex:0];
        id value = [pair.allValues objectAtIndex:0];
        [self appendArgument:key value:value];
    }
    return self;
}

// TODO: support of scalar type
- (void)appendArgument:(NSString *)name value:(id)value {
    if (!arguments_.count) {
        if (name && name.length) {
            unichar ch = toupper([name characterAtIndex:0]);
            NSMutableString *str = [NSMutableString stringWithCharacters:&ch length:1];
            [str appendString:[name substringFromIndex:1]];
            [selector_ appendFormat:@"With%@:", str];
        } else {
            // first parameter without external name
            [selector_ appendString:@":"];
        }
    } else if (name) {
        // non-first parameter
        [selector_ appendFormat:@"%@:", name];
    } // else variadic parameter
    [arguments_ addObject:(value ?: NSNull.null)];
}

- (id)construct {
    Class class = NSClassFromString(name_);
    if (class == nil)  return nil;

    NSRange range = { 0, name_.length };
    [selector_ replaceCharactersInRange:range withString:@"init"];
    return [Invocation construct:class initializer:NSSelectorFromString(selector_) arguments:arguments_];
}

- (ReturnValue *)call:(id)target {
    SEL sel = NSSelectorFromString(selector_);
    return [Invocation call:target selector:sel arguments:arguments_];
}

+ (id)construct:(Class)class initializer:(SEL)sel arguments:(NSArray *)args {
    ReturnValue *result = [Invocation call:[class alloc] selector:sel arguments:args];
    return [result object];
}

+ (ReturnValue *)call:(id)target selector:(SEL)selector arguments:(NSArray *)args {
    return [Invocation call:target selector:selector arguments:args thread:nil];
}
+ (ReturnValue *)call:(id)target selector:(SEL)selector arguments:(NSArray *)args thread:(NSThread *)thread {
    NSMethodSignature *sig = [target methodSignatureForSelector:selector];
    if (sig == nil) {
        [target doesNotRecognizeSelector:selector];
        return nil;
    } else if ([sig numberOfArguments] > args.count + 2) {
        // Too few arguments
        return nil;
    }

    NSInvocation* inv = [NSInvocation invocationWithMethodSignature:sig];
    [inv setSelector:selector];

    // Assemble input parameters
    if (args != nil) {
        for(int i = 0; i < args.count; ++i) {
            NSObject *val = [args objectAtIndex:i];
            const char *type = [sig getArgumentTypeAtIndex:i + 2];
            void *buf = &val;
            if ([val isKindOfClass:[NSNumber class]] && strcmp(type, @encode(id))) {
                // Convert NSNumber to native type if necessary
                NSNumber* num = (NSNumber*)val;
                unsigned long long data;
                buf = &data;
                [num getValue:buf objCType:type];
            } else if (val == NSNull.null) {
                // Convert NSNull to nil
                val = nil;
            }
            [inv setArgument:buf atIndex:(i + 2)];
        }
    }

    if (thread == nil) {
        // synchronized call on current thread
        [inv invokeWithTarget:target];
        return [[ReturnValue alloc] initWithInvocation:inv];
    }

    [inv retainArguments];
    [inv performSelector:@selector(invokeWithTarget:) onThread:thread withObject:target waitUntilDone:false];
    return nil;
}

+ (ReturnValue *)call:(id)target selector:(SEL)selector valist:(va_list)valist {
    return [Invocation call:target selector:selector valist:valist thread:nil];
}
+ (ReturnValue *)call:(id)target selector:(SEL)selector valist:(va_list)valist thread:(NSThread *)thread {
    NSMethodSignature *sig = [target methodSignatureForSelector:selector];
    if (sig == nil) {
        [target doesNotRecognizeSelector:selector];
        return nil;
    }

    NSInvocation* inv = [NSInvocation invocationWithMethodSignature:sig];
    [inv setSelector:selector];

    NSUInteger cnt = [sig numberOfArguments];
    for (NSUInteger i = 2; i < cnt; ++i) {
        const char *type = [sig getArgumentTypeAtIndex: i];
        void *buf = NULL;
        NSUInteger size;
        NSGetSizeAndAlignment(type, NULL, &size);
        if (!strcmp(type, @encode(float))) {
            // The float value is promoted to double
            float data = (float)va_arg(valist, double);
            buf = &data;
        } else if (size < sizeof(int)) {
            // Types narrower than an int are promoted to int.
            if (size == sizeof(short)) {
                short data = (short)va_arg(valist, int);
                buf = &data;
            } else {
                char data = (char)va_arg(valist, int);
                buf = &data;
            }
        } else if (size <= sizeof(long long)) {
            // Any type that size is less or equal than long long.
            long long data = va_arg(valist, long long);
            buf = &data;
        } else {
            NSAssert(false, @"structure type is unsupported.");
        }
        [inv setArgument:buf atIndex: i];
    }

    if (thread == nil) {
        // synchronized call on current thread
        [inv invokeWithTarget:target];
        return [[ReturnValue alloc] initWithInvocation:inv];
    }

    [inv retainArguments];
    [inv performSelector:@selector(invokeWithTarget:) onThread:thread withObject:target waitUntilDone:false];
    return nil;
}

@end


@implementation ReturnValue

- (instancetype)init {
    _objCType = strdup(@encode(void));
    return self;
}

- (instancetype)initWithInvocation:(NSInvocation *)invocation {
    NSMethodSignature *sig = [invocation methodSignature];
    NSUInteger len = [sig methodReturnLength];
    const char *type = [sig methodReturnType];
    if (!len) {
        _objCType = strdup(type);
    } else if (len <= sizeof(unsigned long long)) {
        unsigned long long data;
        [invocation getReturnValue:&data];
        self = [self initWithBytes:&data objCType:type];
    } else {
        void *buf = malloc(len);
        [invocation getReturnValue:buf];
        self = [self initWithBytes:buf objCType:type];
        free(buf);
    }
    return self;
}

- (instancetype)initWithBytes:(const void *)value objCType:(const char *)type {
    _objCType = strdup(type);
    if (!strcmp(type, @encode(id)))
        _object = *(id const *)value;
    else if (!(_number = [NSNumber numberWithBytes:value objCType:type]))
        _value = [NSValue valueWithBytes:value objCType:type];
    return self;
}

- (void)dealloc {
    free((void *)_objCType);
}

- (BOOL)isNumber {
    return _number != nil;
}

#define ISTYPE(n, t) - (BOOL)is##n { return !strcmp(_objCType, @encode(t)); }
ISTYPE(Bool, BOOL)
ISTYPE(Char, char)
ISTYPE(Short, short)
ISTYPE(Int, int)
ISTYPE(Long, long)
ISTYPE(LongLong, long long)
ISTYPE(UnsignedChar, unsigned char)
ISTYPE(UnsignedShort, unsigned short)
ISTYPE(UnsignedInt, unsigned int)
ISTYPE(UnsignedLong, unsigned long)
ISTYPE(UnsignedLongLong, unsigned long long)
ISTYPE(Float, float)
ISTYPE(Double, double)
ISTYPE(Void, void)
ISTYPE(Object, id)
#undef ISTYPE

- (id)forwardingTargetForSelector:(SEL)aSelector {
    NSString *sel = NSStringFromSelector(aSelector);
    if ([sel hasSuffix:@"Value"]) {
        if (_number != nil && [_number respondsToSelector:aSelector])
            return _number;
        if (_object != nil && [_object respondsToSelector:aSelector])
            return _object;
    }
    return nil;
}

@end


@implementation NSNumber (Invocation)

#define ISTYPE(t)       (!strcmp(type, @encode(t)))

+ (NSNumber *)numberWithBytes:(const void *)value objCType:(const char *)type {
#define NUMBER(t, n) return [NSNumber numberWith##n: *(t *)value];
    if ISTYPE(BOOL)                    NUMBER(BOOL, Bool)
    else if ISTYPE(char)               NUMBER(char, Char)
    else if ISTYPE(short)              NUMBER(short, Short)
    else if ISTYPE(int)                NUMBER(int, Int)
    else if ISTYPE(long)               NUMBER(long, Long)
    else if ISTYPE(long long)          NUMBER(long long, LongLong)
    else if ISTYPE(unsigned char)      NUMBER(unsigned char, UnsignedChar)
    else if ISTYPE(unsigned short)     NUMBER(unsigned short, UnsignedShort)
    else if ISTYPE(unsigned int)       NUMBER(unsigned int, UnsignedInt)
    else if ISTYPE(unsigned long)      NUMBER(unsigned long, UnsignedLong)
    else if ISTYPE(unsigned long long) NUMBER(unsigned long long, UnsignedLongLong)
    else if ISTYPE(float)              NUMBER(float, Float)
    else if ISTYPE(double)             NUMBER(double, Double)
    else return nil;
#undef NUMBER
}

- (void)getValue:(void *)buffer objCType:(const char *)type {
#define VALUE(t, n) *(t *)buffer = self.n##Value;
    if ISTYPE(BOOL)                    VALUE(BOOL, bool)
    else if ISTYPE(char)               VALUE(char, char)
    else if ISTYPE(short)              VALUE(short, short)
    else if ISTYPE(int)                VALUE(int, int)
    else if ISTYPE(long)               VALUE(long, long)
    else if ISTYPE(long long)          VALUE(long long, longLong)
    else if ISTYPE(unsigned char)      VALUE(unsigned char, unsignedChar)
    else if ISTYPE(unsigned short)     VALUE(unsigned short, unsignedShort)
    else if ISTYPE(unsigned int)       VALUE(unsigned int, unsignedInt)
    else if ISTYPE(unsigned long)      VALUE(unsigned long, unsignedLong)
    else if ISTYPE(unsigned long long) VALUE(unsigned long long, unsignedLongLong)
    else if ISTYPE(float)              VALUE(float, float)
    else if ISTYPE(double)             VALUE(double, double)
    else [NSException raise:@"TypeError" format:@"'%s' is not a number type", type];
#undef VALUE
}

@end
