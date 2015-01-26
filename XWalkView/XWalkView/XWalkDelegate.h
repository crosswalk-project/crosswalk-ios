// Copyright (c) 2015 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>

@class XWalkChannel;

@protocol XWalkDelegate<NSObject>

@optional
- (void)invokeNativeMethod:(NSString *)name arguments:(NSArray *)args;
- (void)setNativeProperty:(NSString *)name value:(id)value;
- (NSString*)didGenerateStub:(NSString*)stub;
- (void)didBindExtension:(XWalkChannel*)channel instance:(NSInteger)instance;
- (void)didUnbindExtension;

@end
