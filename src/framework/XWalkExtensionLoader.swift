// Copyright (c) 2014 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation

class XWalkExtensionLoader: XWalkExtension {
    func jsfunc_load(cid: UInt32, name: String, namespace: String?, parameter: AnyObject?, _Promise: UInt32) -> Bool {
        if channel.webView.loadExtension(name, namespace: namespace) {
            // TODO: Call success callback with the extension object
            invokeCallback(_Promise, index: 0)
        } else {
            invokeCallback(_Promise, index: 1)
        }
        return true
    }
}
