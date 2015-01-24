// Copyright (c) 2014 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import "XWalkDelegate.h"

@class XWalkChannel;

@interface XWalkExtension : NSObject <XWalkDelegate>

@property(nonatomic, weak) XWalkChannel* channel;
@property(nonatomic, assign) NSInteger instance;

- (NSString*)namespace;
- (void)setProperty:(NSString*)name value:(id)value;

- (void)invokeCallback:(UInt32)callbackId key:(NSString*)key, ... NS_REQUIRES_NIL_TERMINATION;
- (void)invokeCallback:(UInt32)callbackId key:(NSString*)key arguments:(NSArray*)arguments;
- (void)releaseArguments:(UInt32)callId;
- (void)invokeJavaScript:(NSString*)function, ... NS_REQUIRES_NIL_TERMINATION;
- (void)invokeJavaScript:(NSString*)function arguments:(NSArray*)arguments;
- (void)evaluateJavaScript:(NSString*)string;
- (void)evaluateJavaScript:(NSString*)string onSuccess:(void(^)(id))onSuccess onError:(void(^)(NSError*))onError;

// XWalkDelegate implementation
- (NSString*)didGenerateStub:(NSString*)stub;
- (void)didBindExtension:(XWalkChannel*)channel instance:(NSInteger)instance;

@end
