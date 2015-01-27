// Copyright (c) 2014 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioServices.h>

@interface Vibrate : NSObject

- (void)jsfunc_function:(UInt32)callId;

@end

@implementation Vibrate

- (void)jsfunc_function:(UInt32)callId {
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
}

@end
