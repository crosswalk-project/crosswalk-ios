// Copyright (c) 2014 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "XWalkExtension.h"

#import "Invocation.h"
#import "XWalkView/XWalkView-Swift.h"

@interface XWalkExtension()

- (id)objectForKeyedSubscript:(NSString *)key;
- (void)setObject:(id)obj forKeyedSubscript:(id <NSCopying>)key;

@end

@implementation XWalkExtension

- (NSString*)namespace
{
    return self.channel ? self.channel.namespace : nil;
}

- (NSString*)didGenerateStub:(NSString*)stub
{
    NSBundle* bundle = [NSBundle bundleForClass:self.class];
    NSString* name = NSStringFromClass(self.class);
    if (name.pathExtension.length) {
        name = name.pathExtension;
    }
    NSString* path = [bundle pathForResource:name ofType:@"js"];
    if (path) {
        NSError* error = nil;
        NSString* content = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
        return [stub stringByAppendingString:content];
    }
    return stub;
}

- (void)didBindExtension:(XWalkChannel*)channel instance:(NSInteger)instance
{
    self.channel = channel;
    self.instance = instance;
    if (instance == 0) {
        return;
    }

    NSEnumerator* enumerator = [self.channel.mirror.allMembers objectEnumerator];
    id value;
    while (value = [enumerator nextObject]) {
        if ([self.channel.mirror hasProperty:value]) {
            [self setProperty:value value:self[value]];
        }
    }
}

- (void)setProperty:(NSString*)name value:(id)value
{
    // TODO: check type
    id var = value ? value : nil;
    NSString* json = nil;
    if ([var isKindOfClass:NSString.class]) {
        json = [NSString stringWithFormat:@"'%@'", (NSString*)var];
    } else {
        NSError* error = nil;
        NSData* data = [NSJSONSerialization dataWithJSONObject:var options:NSJSONWritingPrettyPrinted error:&error];
        if (error) {
            NSLog(@"ERROR: Failed to generate json string from var object.");
            return;
        }
        json = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    NSString* script = nil;
    if (self.instance) {
        script = [NSString stringWithFormat:@"%@[%lu].properties['%@'] = %@;", self.channel.namespace, self.instance, name, json];
    } else {
        script = [NSString stringWithFormat:@"%@.properties['%@'] = %@;", self.channel.namespace, name, json];
    }
    [self evaluateJavaScript:script];
}

- (void)invokeCallback:(UInt32)callId
{
    [self invokeCallback:callId key:nil];
}

- (void)invokeCallback:(UInt32)callId key:(NSString*)key
{
    [self invokeCallback:callId key:key arguments:nil];
}

- (void)invokeCallback:(UInt32)callId key:(NSString*)key arguments:(NSArray*)arguments
{
    NSArray* args = [NSArray arrayWithObjects:[NSNumber numberWithInteger:callId], key ? key : [NSNull null], arguments, nil];
    [self invokeJavaScript:@".invokeCallback" arguments:args];
}

- (void)invokeCallback:(UInt32)callId index:(UInt32)index
{
    [self invokeCallback:callId index:index arguments:nil];
}

- (void)invokeCallback:(UInt32)callId index:(UInt32)index arguments:(NSArray*)arguments
{
    NSArray* args = [NSArray arrayWithObjects:[NSNumber numberWithInteger:callId], [NSNumber numberWithInteger:index], arguments, nil];
    [self invokeJavaScript:@".invokeCallback" arguments:args];
}

- (void)releaseArguments:(UInt32)callId
{
    [self invokeJavaScript:@".releaseArguments" arguments:@[[NSNumber numberWithUnsignedInteger:callId]]];
}

- (void)invokeJavaScript:(NSString*)function
{
    [self invokeJavaScript:function arguments:nil];
}

- (void)invokeJavaScript:(NSString*)function arguments:(NSArray*)arguments
{
    NSMutableString* script = [NSMutableString stringWithString:function];
    NSMutableString* this = [NSMutableString stringWithString:@"null"];
    if ([script characterAtIndex:0] == '.') {
        // Invoke a method of this object
        [this setString:self.channel.namespace];
        if (self.instance) {
            [this appendString:[NSString stringWithFormat:@"[%@]", [NSNumber numberWithInteger:self.instance]]];
        }
        [script insertString:this atIndex:0];
    }

    NSError* error;
    NSData* data = [NSJSONSerialization dataWithJSONObject:arguments options:NSJSONWritingPrettyPrinted error:&error];
    if (error) {
        NSLog(@"ERROR: Failed to generate json string from arguments object.");
        return;
    }
    NSString* json = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    [script appendString:[NSString stringWithFormat:@".apply(%@, %@);", this, json]];
    [self evaluateJavaScript:script];
}

- (void)evaluateJavaScript:(NSString*)string
{
    [self.channel evaluateJavaScript:string completionHandler:^void(id obj, NSError* err) {
        if (err) {
            NSLog(@"ERROR: Failed to execute script, %@\n------------\n%@\n------------", err, string);
        }
    }];
}

- (void)evaluateJavaScript:(NSString*)string onSuccess:(void(^)(id))onSuccess onError:(void(^)(NSError*))onError
{
    [self.channel evaluateJavaScript:string completionHandler:^void(id obj, NSError*err) {
        err ? onSuccess(obj) : onError(err);
    }];
}

- (id)objectForKeyedSubscript:(NSString *)key
{
    SEL selector = [self.channel.mirror getGetter:key];
    if (selector) {
        ReturnValue* result = [Invocation call:self selector:[self.channel.mirror getGetter:key] arguments:nil];
        id obj = result.object ? result.object : result.number;
        if (obj) {
            return obj;
        } else if (![result.object isKindOfClass:NSNull.class]) {
            [NSException raise:@"PropertyError" format:@"Type of property '%@' is unknown.", key];
        }
    } else {
        [NSException raise:@"PropertyError" format:@"Property '%@' is not defined.", key];
    }
    return nil;
}

- (void)setObject:(id)obj forKeyedSubscript:(id <NSCopying>)key
{
    NSString* name = (NSString*)key;
    SEL selector = [self.channel.mirror getSetter:name];
    if (selector) {
        if (![self.channel.mirror getOriginalSetter:name]) {
            [self setProperty:name value:obj];
        }
        [Invocation call:self selector:selector arguments:obj ? obj : [NSNull null]];
    } else if ([self.channel.mirror hasProperty:name]) {
        [NSException raise:@"PropertyError" format:@"Property '%@' is readonly.", name];
    } else {
        [NSException raise:@"PropertyError" format:@"Property '%@' is undefined.", name];
    }
}

@end
