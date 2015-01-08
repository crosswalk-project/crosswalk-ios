// Copyright (c) 2014 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "CommandQueue.h"

#import "CDVInvokedUrlCommand.h"
#import "CDVJSON.h"
#import "CDVPlugin.h"
#import "CrosswalkLite/Invocation.h"
#import "NSMutableArray+QueueAdditions.h"

@interface CommandQueue()

@property(nonatomic, strong) NSMutableArray* queue;

@end

@implementation CommandQueue

- (id)init
{
    self = [super init];
    if (self) {
        self.queue = [[NSMutableArray alloc] init];
    }
    return self;
}

- (BOOL)enqueueCommandBatch:(NSString*)batchJSON
{
    if ([batchJSON length] == 0) {
        return NO;
    }

    NSArray *commands = (NSArray*)[batchJSON JSONObject];
    for (NSInteger i = 0; i < commands.count; i++) {
        [self.queue addObject:[CDVInvokedUrlCommand commandFromJson:(NSArray*)commands[i]]];
    }
    return YES;
}

- (BOOL)execute:(CDVInvokedUrlCommand*)command;
{
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
        [Invocation call:plugin selector:sel arguments:[NSArray arrayWithObject:command]];
    } else {
        NSLog(@"ERROR: Method %@ not defined in plugin: %@", command.methodName, command.className);
        return NO;
    }

    return YES;
}

- (void)executePending
{
    while (self.queue.count) {
        CDVInvokedUrlCommand* command = [self.queue dequeue];
        if (![self execute:command]) {
            NSLog(@"ERROR: Failed to execute command");
        }
    }
}

@end
