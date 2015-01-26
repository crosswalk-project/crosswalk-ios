// Copyright (c) 2014 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "XWalkExtension.h"

#import "Invocation.h"
#import "XWalkView/XWalkView-Swift.h"

@interface XWalkExtension()

@property(nonatomic, weak) XWalkChannel* channel;
@property(nonatomic, assign) NSInteger instance;

- (id)objectForKeyedSubscript:(NSString *)key;
- (void)setObject:(id)obj forKeyedSubscript:(id <NSCopying>)key;

@end

@implementation XWalkExtension {
    BOOL _sync;
}

- (NSString*)namespace {
    return self.channel ? self.channel.namespace : nil;
}

- (void)invokeNativeMethod:(NSString *)name arguments:(NSArray *)args {
    SEL selector = [self.channel.mirror getMethod:name];
    if (!selector) {
        NSLog(@"ERROR: Method '%@' is undefined in class '%@'.", name, NSStringFromClass(self.class));
        return;
    }

    ReturnValue *result = [Invocation call:self selector:selector arguments:args];
    if (result.isBool && result.boolValue == YES)
        [self releaseArguments:((NSNumber *)args[0]).unsignedIntValue];
}

- (void)setNativeProperty:(NSString *)name value:(id)value {
    SEL selector = [self.channel.mirror getSetter:name];
    if (!selector) {
        if ([self.channel.mirror hasProperty:name])
            NSLog(@"ERROR: Property '%@' is readonly.", name);
        else
            NSLog(@"ERROR: Property '%@' is undefined in class '%@'.", name, NSStringFromClass(self.class));
        return;
    }

    _sync = NO;
    [Invocation call:self selector:selector arguments:@[value]];
    _sync = YES;
}

- (NSString*)didGenerateStub:(NSString*)stub {
    NSBundle* bundle = [NSBundle bundleForClass:self.class];
    NSString* name = NSStringFromClass(self.class);
    if (name.pathExtension.length) {
        name = name.pathExtension;
    }
    NSString* path = [bundle pathForResource:name ofType:@"js"];
    if (path) {
        NSString* content = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
        if (content)
            return [stub stringByAppendingString:content];
    }
    return stub;
}

- (void)didBindExtension:(XWalkChannel*)channel instance:(NSInteger)instance {
    self.channel = channel;
    self.instance = instance;

    NSEnumerator* enumerator = [self.channel.mirror.allProperties objectEnumerator];
    NSString *name;
    while (name = [enumerator nextObject]) {
        NSString *key = NSStringFromSelector([self.channel.mirror getGetter:name]);
        [self addObserver:self forKeyPath:key options:NSKeyValueObservingOptionNew context:(__bridge void *)self];
        if (instance)
            [self setJavaScriptProperty:name value:self[name]];
    }
    _sync = YES;
}

- (void)didUnbindExtension {
    NSEnumerator* enumerator = [self.channel.mirror.allProperties objectEnumerator];
    id name;
    while (name = [enumerator nextObject]) {
        NSString *key = NSStringFromSelector([self.channel.mirror getGetter:name]);
        [self removeObserver:self forKeyPath:key context:(__bridge void *)self];
    }

    self.channel = nil;
    self.instance = 0;
}

- (void)setJavaScriptProperty:(NSString*)name value:(id)value {
    NSString* json = nil;
    if (value == nil || value == NSNull.null) {
        json = @"null";
    } else if ([value isKindOfClass:NSString.class]) {
        json = [NSString stringWithFormat:@"'%@'", (NSString*)value];
    } else if ([value isKindOfClass:NSNumber.class]) {
        json = [NSString stringWithFormat:@"%@", value];
    } else {
        NSError* error = nil;
        NSData* data = [NSJSONSerialization dataWithJSONObject:value options:NSJSONWritingPrettyPrinted error:&error];
        if (error) {
            NSLog(@"ERROR: Failed to generate json string from value object.");
            return;
        }
        json = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    NSString *script = [NSString stringWithFormat:@"%@.properties['%@'] = %@;",
            self.instance ? [self.namespace stringByAppendingFormat:@"[%zd]", self.instance] : self.namespace, name, json];
    [self evaluateJavaScript:script];
}

- (void)invokeCallback:(UInt32)callbackId key:(NSString*)key, ... {
    NSMutableArray *args = [NSMutableArray new];
    va_list ap;
    id arg;
    va_start(ap, key);
    while ((arg = va_arg(ap, id)) != nil) {
        [args addObject:arg];
    }
    va_end(ap);
    [self invokeJavaScript:@".invokeCallback", [NSNumber numberWithInteger:callbackId], key ?: NSNull.null, args, nil];
}

- (void)invokeCallback:(UInt32)callbackId key:(NSString*)key arguments:(NSArray*)arguments {
    [self invokeJavaScript:@".invokeCallback", [NSNumber numberWithInteger:callbackId], key ?: NSNull.null, arguments, nil];
}

- (void)releaseArguments:(UInt32)callId {
    [self invokeJavaScript:@".releaseArguments", [NSNumber numberWithUnsignedInteger:callId], nil];
}

- (void)invokeJavaScript:(NSString*)function, ... {
    NSMutableArray *args = [NSMutableArray new];
    va_list ap;
    id arg;
    va_start(ap, function);
    while ((arg = va_arg(ap, id)) != nil) {
        [args addObject:arg];
    }
    [self invokeJavaScript:function arguments:args];
    va_end(ap);
}

- (void)invokeJavaScript:(NSString*)function arguments:(NSArray*)arguments {
    NSMutableString* script = [NSMutableString stringWithString:function];
    NSMutableString* this = [NSMutableString stringWithString:@"null"];
    if ([script characterAtIndex:0] == '.') {
        // Invoke a method of this object
        [this setString:self.namespace];
        if (self.instance)
            [this appendFormat:@"[%zd]", self.instance];
        [script insertString:this atIndex:0];
    }

    NSString* json = @"[]";
    if (arguments != nil) {
        NSError* error;
        NSData* data = [NSJSONSerialization dataWithJSONObject:arguments options:NSJSONWritingPrettyPrinted error:&error];
        if (error) {
            NSLog(@"ERROR: Failed to generate json string from arguments object.");
            return;
        }
        json = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    [script appendString:[NSString stringWithFormat:@".apply(%@, %@);", this, json]];
    [self evaluateJavaScript:script];
}

- (void)evaluateJavaScript:(NSString*)string {
    [self.channel evaluateJavaScript:string completionHandler:^void(id obj, NSError* err) {
        if (err) {
            NSLog(@"ERROR: Failed to execute script, %@\n------------\n%@\n------------", err, string);
        }
    }];
}

- (void)evaluateJavaScript:(NSString*)string onSuccess:(void(^)(id))onSuccess onError:(void(^)(NSError*))onError {
    [self.channel evaluateJavaScript:string completionHandler:^void(id obj, NSError*err) {
        err ? onSuccess(obj) : onError(err);
    }];
}

- (id)objectForKeyedSubscript:(NSString *)key {
    SEL selector = [self.channel.mirror getGetter:key];
    if (selector) {
        ReturnValue* result = [Invocation call:self selector:selector arguments:nil];
        if (result.isObject || result.isNumber)
            return result.object ?: result.number;
        else
            [NSException raise:@"PropertyError" format:@"Type of property '%@' is unknown.", key];
    } else {
        [NSException raise:@"PropertyError" format:@"Property '%@' is undefined.", key];
    }
    return nil;
}

- (void)setObject:(id)obj forKeyedSubscript:(id <NSCopying>)key {
    NSString* name = (NSString*)key;
    SEL selector = [self.channel.mirror getSetter:name];
    if (selector) {
        if (!_sync)
            [self setJavaScriptProperty:name value:obj];
        [Invocation call:self selector:selector arguments:obj ?: NSNull.null];
    } else if ([self.channel.mirror hasProperty:name]) {
        [NSException raise:@"PropertyError" format:@"Property '%@' is readonly.", name];
    } else {
        [NSException raise:@"PropertyError" format:@"Property '%@' is undefined.", name];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    // FIXME: This class should not know the mapping between selector and property name.
    if (context == (__bridge void *)(self) && _sync)
        [self setJavaScriptProperty:[keyPath substringFromIndex:7] value:change[NSKeyValueChangeNewKey]];
}

@end
