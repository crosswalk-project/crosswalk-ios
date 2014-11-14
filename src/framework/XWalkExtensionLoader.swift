// Copyright (c) 2014 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation

private let api: String = "" +
    "exports.load = function(name, namespace) {" +
    "    var loader = this;" +
    "    return new Promise(function(resolve, reject) {" +
    "        var callID = loader.addCallback({" +
    "                'resolve': resolve," +
    "                'reject': reject" +
    "        });" +
    "        loader.invokeNative('load', [" +
    "                {'name': name}," +
    "                {'namespace': namespace? namespace: null}," +
    "                {'callback': callID}" +
    "        ]);" +
    "    });" +
    "}"

class XWalkExtensionLoader: XWalkExtension {
    override var jsAPIStub : String {
        return api
    }

    func js_load(name: String, namespace: String?, callback: NSNumber) {
        if let ext = XWalkExtensionFactory.singleton.createExtension(name) {
            ext.attach(super.webView!, namespace: namespace)
            invokeCallback(callback.intValue, key: "resolve", arguments: nil)
        } else {
            invokeCallback(callback.intValue, key: "reject", arguments: nil)
        }
    }
}
