// Copyright (c) 2014,2015 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "CommandQueue.h"

#import "CDVInvokedUrlCommand.h"
#import "CDVJSON_private.h"
#import "CDVPlugin.h"
#import "XWalkView/XWalkInvocation.h"
#import "NSMutableArray+QueueAdditions.h"

@interface CommandQueue()

@property(nonatomic, assign, readonly) NSInteger lastCommandQueueFlushRequestId;
@property(nonatomic, strong) NSMutableArray* queue;
@property(nonatomic, assign) NSTimeInterval startExecutionTime;

@end

@implementation CommandQueue

static const NSInteger JSON_SIZE_FOR_MAIN_THREAD = 4 * 1024; // Chosen arbitrarily.
static const double MAX_EXECUTION_TIME = .008; // Half of a 60fps frame.

- (id)init {
    self = [super init];
    if (self) {
        self.queue = [[NSMutableArray alloc] init];
    }
    return self;
}

- (BOOL)currentlyExecuting {
    return _startExecutionTime > 0;
}

- (void)resetRequestId {
    _lastCommandQueueFlushRequestId = 0;
}

- (BOOL)enqueueCommandBatch:(NSString*)batchJSON {
    if ([batchJSON length] == 0) {
        return NO;
    }

    NSMutableArray* commandBatchHolder = [[NSMutableArray alloc] init];
    [self.queue addObject:commandBatchHolder];
    if (batchJSON.length < JSON_SIZE_FOR_MAIN_THREAD) {
        [commandBatchHolder addObject:[batchJSON cdv_JSONObject]];
    } else {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSMutableArray* result = [batchJSON cdv_JSONObject];
            @synchronized(commandBatchHolder) {
                [commandBatchHolder addObject:result];
            }
            [self performSelectorOnMainThread:@selector(executePending) withObject:nil waitUntilDone:NO];
        });
    }

    return YES;
}

- (BOOL)execute:(CDVInvokedUrlCommand*)command {
    if (!command.className || !command.methodName) {
        NSLog(@"ERROR: Classname and/or methodName not found for command.");
        return NO;
    }

    CDVPlugin* plugin = [self.delegate getPluginInstance:command.className];
    if (!plugin) {
        NSLog(@"ERROR: Failed to find plugin instance for class: %@", command.className);
        return NO;
    }

    SEL sel = NSSelectorFromString([command.methodName stringByAppendingString:@":"]);
    if ([plugin respondsToSelector:sel]) {
        [XWalkInvocation call:plugin selector:sel, command];
    } else {
        NSLog(@"ERROR: Method %@ not defined in plugin: %@", command.methodName, command.className);
        return NO;
    }

    return YES;
}

- (void)executePending {
    if (_startExecutionTime > 0) {
        return;
    }

    @try {
        _startExecutionTime = [NSDate timeIntervalSinceReferenceDate];
        while (self.queue.count) {
            NSMutableArray* commandBatchHolder = self.queue[0];
            NSMutableArray* commandBatch = nil;
            @synchronized(commandBatchHolder) {
                if (commandBatchHolder.count == 0) {
                    break;
                }
                commandBatch = commandBatchHolder[0];
            }
            while (commandBatch.count) {
                @autoreleasepool {
                    NSArray* jsonEntry = [commandBatch cdv_dequeue];
                    if (commandBatch.count == 0) {
                        [_queue removeObjectAtIndex:0];
                    }
                    CDVInvokedUrlCommand* command = [CDVInvokedUrlCommand commandFromJson:jsonEntry];
                    CDV_EXEC_LOG(@"Exec(%@): Calling %@.%@", command.callbackId, command.className, command.methodName);

                    if (![self execute:command]) {
                        NSString* commandJson = [jsonEntry cdv_JSONString];
                        static NSUInteger maxLogLength = 1024;
                        NSString* commandString = (commandJson.length > maxLogLength) ? [NSString stringWithFormat:@"%@[...]", [commandJson substringToIndex:maxLogLength]] : commandJson;
                        NSLog(@"FAILED pluginJSON = %@", commandString);

                    }

                    // Yield if we're talking too long.
                    if ((_queue.count > 0) && ([NSDate timeIntervalSinceReferenceDate] - _startExecutionTime > MAX_EXECUTION_TIME)) {
                        [self performSelector:@selector(executePending) withObject:nil afterDelay:0];
                        return;
                    }
                }
            }
        }
    }
    @catch (NSException *exception) {
        NSLog(@"ERROR: Exeption thrown when executing pending command. %@, %@", exception.name, exception.reason);
    }
    @finally {
        _startExecutionTime = 0;
    }
}

@end
