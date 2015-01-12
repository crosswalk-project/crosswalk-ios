// Copyright (c) 2014 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef XWalkView_XWalkHttpConnection_h
#define XWalkView_XWalkHttpConnection_h

#import <Foundation/Foundation.h>

@class XWalkHttpConnection;

@protocol XWalkHttpConnectionDelegate <NSObject>

@optional
@property (readonly, nonatomic) NSString* documentRoot;
- (void)didOpenConnection:(XWalkHttpConnection *)connection;
- (void)didCloseConnection:(XWalkHttpConnection *)connection;

@end

@interface XWalkHttpConnection : NSObject<NSStreamDelegate>

@property (weak, nonatomic) id<XWalkHttpConnectionDelegate> delegate;

- (id)initWithNativeHandle:(CFSocketNativeHandle)handle;
- (BOOL)open;
- (void)close;

@end


#endif
