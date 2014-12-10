// Copyright (c) 2014 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/*
 Be sure to import this file in your project's bridging header file.
 #import "Invocation.h"
 */

@import Foundation;

@interface ReturnValue : NSObject

@property (readonly, nonatomic) const char *objCType;
@property (readonly, nonatomic) id object;
@property (readonly, nonatomic) NSNumber *number;
@property (readonly, nonatomic) NSValue *value;

@property (readonly, nonatomic) BOOL isBool;
@property (readonly, nonatomic) BOOL isChar;
@property (readonly, nonatomic) BOOL isShort;
@property (readonly, nonatomic) BOOL isInt;
@property (readonly, nonatomic) BOOL isLong;
@property (readonly, nonatomic) BOOL isLongLong;
@property (readonly, nonatomic) BOOL isUnsignedChar;
@property (readonly, nonatomic) BOOL isUnsignedShort;
@property (readonly, nonatomic) BOOL isUnsignedInt;
@property (readonly, nonatomic) BOOL isUnsignedLong;
@property (readonly, nonatomic) BOOL isUnsignedLongLong;
@property (readonly, nonatomic) BOOL isFloat;
@property (readonly, nonatomic) BOOL isDouble;

@property (readonly, nonatomic) BOOL isNumber;
@property (readonly, nonatomic) BOOL isObject;
@property (readonly, nonatomic) BOOL isVoid;

- (instancetype)init;
- (instancetype)initWithBytes:(const void *)value objCType:(const char *)type;
- (instancetype)initWithInvocation:(NSInvocation *)invocation;

@end

@interface ReturnValue (NumberValue)

@property (readonly) BOOL boolValue;
@property (readonly) char charValue;
@property (readonly) NSDecimal decimalValue;
@property (readonly) double doubleValue;
@property (readonly) float floatValue;
@property (readonly) int intValue;
@property (readonly) NSInteger integerValue;
@property (readonly) long longValue;
@property (readonly) long long longLongValue;
@property (readonly) short shortValue;
@property (readonly) unsigned char unsignedCharValue;
@property (readonly) NSUInteger unsignedIntegerValue;
@property (readonly) unsigned int unsignedIntValue;
@property (readonly) unsigned long long unsignedLongLongValue;
@property (readonly) unsigned long unsignedLongValue;
@property (readonly) unsigned short unsignedShortValue;

@end

@interface Invocation : NSObject

- (id)initWithName:(NSString *)name;
- (id)initWithArguments:(NSString *)name arguments:(NSArray *)arg;

- (void)appendArgument:(NSString *)name value:(id)value;

- (ReturnValue *)call:(id)target;

+ (ReturnValue *)call:(id)target selector:(SEL)selector arguments:(NSArray *)arg;

@end
