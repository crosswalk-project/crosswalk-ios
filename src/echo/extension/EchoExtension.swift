// Copyright (c) 2014 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import CrosswalkLite

class EchoExtension: XWalkExtension {
    var jsprop_prefix: String = ""
    convenience init(param: AnyObject) {
        self.init()
        if let prefix = param as? NSString {
            jsprop_prefix = prefix
        }
    }
    func jsfunc_echo(cid: UInt32, message: String, callback: UInt32) -> Bool {
        invokeCallback(callback, arguments: [jsprop_prefix + message])
        return true
    }
}
