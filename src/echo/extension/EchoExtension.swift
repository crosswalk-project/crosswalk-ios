// Copyright (c) 2014 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import CrosswalkLite

class EchoExtension: XWalkExtension {
    var jsprop_prefix: String = "prefix:"
    func jsfunc_echo(cid: NSNumber, message: String, callback: NSNumber) {
        invokeCallback(callback.unsignedIntValue, arguments: [jsprop_prefix + message])
    }
}
