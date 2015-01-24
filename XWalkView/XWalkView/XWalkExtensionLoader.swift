// Copyright (c) 2014 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation
import WebKit

class XWalkExtensionLoader: XWalkExtension {
    func jsfunc_function(cid: UInt32, name: String, namespace: String?, argument: AnyObject?, _Promise: UInt32) -> Bool {
        let initializer: Selector = argument == nil ? "init" : "initWithJSValue:"
        let arguments: [AnyObject] = argument == nil ? [] : [argument!]
        if let ext: AnyObject = XWalkExtensionFactory.createExtension(name, initializer: initializer, arguments: arguments) {
            channel.webView.loadExtension(ext, namespace: namespace ?? name)
            // TODO: Call success callback with the extension object
            invokeCallback(_Promise, key:"resolve", arguments: nil)
        } else {
            invokeCallback(_Promise, key:"reject", arguments: nil)
        }
        return true
    }
}
