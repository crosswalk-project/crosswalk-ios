// Copyright (c) 2014 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import XWalkView

class EchoExtension: XWalkExtension {
    dynamic var jsprop_prefix: String = ""

    convenience init(prefix: String) {
        self.init()
        jsprop_prefix = prefix
    }
    convenience init(JSValue value: AnyObject) {
        self.init()
        if let prefix = value as? String {
            jsprop_prefix = prefix
        } else if let num = value as? NSNumber {
            jsprop_prefix = num.stringValue
        }
    }

    func jsfunc_echo(cid: UInt32, message: String, callback: UInt32) -> Bool {
        invokeCallback(callback, key: nil, arguments: [jsprop_prefix + message])
        return true
    }
}
