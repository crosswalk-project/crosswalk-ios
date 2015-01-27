// Copyright (c) 2014 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import XWalkView

class Echo: XWalkExtension {
    dynamic var jsprop_prefix: String = ""

    func jsfunc_echo(cid: UInt32, message: String, callback: UInt32) -> Bool {
        invokeCallback(callback, key: nil, arguments: [jsprop_prefix + message])
        return true
    }

    convenience init(fromJavaScript: AnyObject?, value: AnyObject?) {
        self.init()
        if let prefix: AnyObject = value {
            if let prefix = value as? String {
                jsprop_prefix = prefix
            } else if let num = value as? NSNumber {
                jsprop_prefix = num.stringValue
            }
        }
    }
}
