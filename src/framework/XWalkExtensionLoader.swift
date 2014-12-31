// Copyright (c) 2014 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation
import WebKit

class XWalkExtensionLoader: XWalkExtension {
    func jsfunc_load(cid: UInt32, name: String, namespace: String?, parameter: AnyObject?, _Promise: UInt32) -> Bool {
        if let object: AnyObject = XWalkExtensionFactory.createExtension(name, parameter: parameter) {
            channel.webView.loadExtension(object, namespace: namespace ?? name)
            // TODO: Call success callback with the extension object
            invokeCallback(_Promise, index: 0)
        } else {
            invokeCallback(_Promise, index: 1)
        }
        return true
    }
}
