// Copyright (c) 2014 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation

public class XWalkThread : NSThread {
    var timer: NSTimer!

    deinit {
        cancel()
    }

    override public func main() {
        repeat {
            switch  CFRunLoopRunInMode(kCFRunLoopDefaultMode, 60, true) {
                case CFRunLoopRunResult.Finished:
                    // No input source, add a timer (which will never fire) to avoid spinning.
                    let interval = NSDate.distantFuture().timeIntervalSinceNow
                    timer = NSTimer(timeInterval: interval, target: self, selector: Selector(), userInfo: nil, repeats: false)
                    NSRunLoop.currentRunLoop().addTimer(timer, forMode: NSDefaultRunLoopMode)
                case CFRunLoopRunResult.HandledSource:
                    // Remove the timer because run loop has had input source
                    if timer != nil {
                        timer.invalidate()
                        timer = nil
                    }
                case CFRunLoopRunResult.Stopped:
                    cancel()
                default:
                    break
            }
        } while !cancelled
    }
}
