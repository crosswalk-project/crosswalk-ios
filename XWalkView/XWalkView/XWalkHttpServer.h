// Copyright (c) 2014 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef XWalkView_XWalkHttpServer_h
#define XWalkView_XWalkHttpServer_h

#import <Foundation/Foundation.h>

@interface XWalkHttpServer : NSObject

@property(nonatomic, readonly) in_port_t port;

- (id)initWithDocumentRoot:(NSString *)root;
- (BOOL)start:(NSThread *)thread;
- (void)stop;

@end

#endif
