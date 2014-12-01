// Copyright (c) 2014 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation

class XWalkExtensionLoader: XWalkExtension {
    func jsfunc_load(cid: NSNumber, name: String, namespace: String?, _Promise: NSNumber) {
        if let ext = XWalkExtensionFactory.singleton.createExtension(name) {
            ext.attach(super.webView!, namespace: namespace)
            invokeCallback(_Promise.unsignedIntValue, index: 0)
        } else {
            invokeCallback(_Promise.unsignedIntValue, index: 1)
        }
    }
}
