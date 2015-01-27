// Copyright (c) 2014 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import XWalkView

class HelloWorld : NSObject {
    func jsfunc_show(callId: UInt32) {
        dispatch_async(dispatch_get_main_queue()) {
            let alert = UIAlertView(title: "Hello World!", message: "(from Crosswalk)", delegate: nil, cancelButtonTitle: "OK")
            alert.show()
        }
    }
}
