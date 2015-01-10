// Copyright (c) 2014 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation

class XWalkThread : NSThread {
    deinit {
        cancel()
    }
    override func main() {
        let runloop = NSRunLoop.currentRunLoop()
        do {
            //TODO: add an input source (timer?)
            runloop.runMode(NSDefaultRunLoopMode, beforeDate: NSDate.distantFuture() as NSDate)
        } while !cancelled
    }
}
