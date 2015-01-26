// Copyright (c) 2014 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#if !defined(__has_feature) || !__has_feature(objc_arc)
#error "This file requires ARC support."
#endif

#include <sys/socket.h>
#include <netinet/in.h>

#import "XWalkHttpServer.h"
#import "XWalkHttpConnection.h"

@interface XWalkHttpServer () <XWalkHttpConnectionDelegate>
@end

@implementation XWalkHttpServer {
    CFSocketRef _socket;
    NSMutableSet *_connections;
    NSString *_documentRoot;
}

- (in_port_t)port {
    in_port_t port = 0;
    if (_socket != NULL) {
        NSData *addr = (__bridge_transfer NSData *)CFSocketCopyAddress(_socket);
        port = ntohs(((const struct sockaddr_in *)[addr bytes])->sin_port);
    }
    return port;
}

- (NSString *)documentRoot {
    return _documentRoot;
}

- (id)initWithDocumentRoot:(NSString *)root {
    BOOL isDirectory;
    if (![[NSFileManager defaultManager] fileExistsAtPath:root isDirectory:&isDirectory] || !isDirectory) {
        return nil;
    }
    _connections = [[NSMutableSet alloc] init];
    _documentRoot = [root copy];
    return self;
}

- (void)dealloc {
    [self stop];
}

- (void)didCloseConnection:(NSNotification *)connection {
    [_connections removeObject:connection];
}

static void ServerAcceptCallBack(CFSocketRef socket, CFSocketCallBackType type, CFDataRef address, const void *data, void *info) {
    XWalkHttpServer *server = (__bridge XWalkHttpServer *)info;
    CFSocketNativeHandle handle = *(CFSocketNativeHandle *)data;
    assert(socket == server->_socket && type == kCFSocketAcceptCallBack);

    XWalkHttpConnection * conn = [[XWalkHttpConnection alloc] initWithNativeHandle:handle];
    [server->_connections addObject:conn];
    conn.delegate = server;
    [conn open];
}

- (BOOL)start:(NSThread *)thread {
    assert(_socket == NULL);

    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_len = sizeof(addr);
    addr.sin_family = AF_INET;
    addr.sin_port = htons(0);
    addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    NSData *address = [NSData dataWithBytes:&addr length:sizeof(addr)];
    CFSocketSignature signature = {PF_INET, SOCK_STREAM, IPPROTO_TCP, (__bridge CFDataRef)(address)};

    CFSocketContext context = {0, (__bridge void *)self, NULL, NULL, NULL};
    _socket = CFSocketCreateWithSocketSignature(kCFAllocatorDefault, &signature, kCFSocketAcceptCallBack, &ServerAcceptCallBack, &context);
    if (socket == NULL)  return NO;

    const int yes = 1;
    setsockopt(CFSocketGetNative(_socket), SOL_SOCKET, SO_REUSEADDR, &yes, sizeof(yes));

    // Get the runloop of server thread
    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
    if (thread != nil && thread != [NSThread currentThread]) {
        NSInvocation *inv = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:@selector(runLoop)]];
        inv.selector = @selector(runLoop);
        [inv performSelector:@selector(invokeWithTarget:) onThread:thread withObject:self waitUntilDone:YES];
        __unsafe_unretained id returnValue;
        [inv getReturnValue:&returnValue];
        runLoop = returnValue;
    }

    CFRunLoopSourceRef source = CFSocketCreateRunLoopSource(kCFAllocatorDefault, _socket, 0);
    CFRunLoopAddSource(runLoop.getCFRunLoop, source, kCFRunLoopCommonModes);
    CFRelease(source);
    return YES;
}

- (void)stop {
    // Close all connections.
    for (XWalkHttpConnection * conn in _connections) {
        conn.delegate = nil;
        [conn close];
    }
    _connections = [NSMutableSet new];

    // Close server socket.
    if (_socket != NULL) {
        CFSocketInvalidate(_socket);
        CFRelease(_socket);
        _socket = NULL;
    }
}

- (NSRunLoop *)runLoop {
    return [NSRunLoop currentRunLoop];
}

@end
