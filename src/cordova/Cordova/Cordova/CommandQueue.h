// Copyright (c) 2014 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>

@class CDVPlugin;
@class CDVInvokedUrlCommand;

@protocol CommandQueueDelegate <NSObject>

- (CDVPlugin*)getPluginInstance:(NSString*)className;

@end

@interface CommandQueue : NSObject

@property(nonatomic, weak) id <CommandQueueDelegate> delegate;

- (BOOL)enqueueCommandBatch:(NSString*)batchJSON;
- (void)executePending;
- (BOOL)execute:(CDVInvokedUrlCommand*)command;

@end
