// Copyright (c) 2014 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation

class XWalkThread : NSThread {
    var timer: NSTimer!

    deinit {
        cancel()
    }

    override func main() {
        do {
            switch  Int(CFRunLoopRunInMode(kCFRunLoopDefaultMode, 60, Boolean(1))) {
                case kCFRunLoopRunFinished:
                    // No input source, add a timer (which will never fire) to avoid spinning.
                    let interval = NSDate.distantFuture().timeIntervalSinceNow
                    timer = NSTimer(timeInterval: interval, target: self, selector: Selector(), userInfo: nil, repeats: false)
                    NSRunLoop.currentRunLoop().addTimer(timer, forMode: NSDefaultRunLoopMode)
                case kCFRunLoopRunHandledSource:
                    // Remove the timer because run loop has had input source
                    if timer != nil {
                        timer.invalidate()
                        timer = nil
                    }
                case kCFRunLoopRunStopped:
                    cancel()
                default:
                    break
            }
        } while !cancelled
    }
}
