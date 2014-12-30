// Copyright (c) 2014 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation

class XWalkStubGenerator {
    let mirror: XWalkReflection

    init(cls: AnyClass) {
        mirror = XWalkReflection(cls: cls)
    }
    init(reflection: XWalkReflection) {
        mirror = reflection
    }

    func generate(channelName: String, namespace: String, object: AnyObject? = nil) -> String {
        var stub = "Extension.create(\(channelName), '\(namespace)');\n"

        for name in mirror.allMembers {
            if mirror.hasMethod(name) {
                stub += "\(namespace).\(name) = \(generateMethodStub(name))\n"
            } else {
                var value = "undefined"
                if object != nil {
                    // Fetch initial value
                    let result = Invocation.call(object, selector: mirror.getGetter(name)!, arguments: nil)
                    var val: AnyObject? = result.object ?? result.number ?? NSNull()
                    if val as? String != nil {
                        val = "'\(val)'"
                    }
                    value = JSON(val!).toString()
                }
                stub += "\(namespace).defineProperty('\(name)', \(value), \(!mirror.isReadonly(name)!));\n"
            }
        }
        return stub
    }

    private func generateMethodStub(name: String) -> String {
        var params = mirror.getMethod(name)!.description.componentsSeparatedByString(":")
        params.removeAtIndex(0)
        params.removeLast()

        // deal with parameters without external name
        for i in 0...params.count-1 {
            if params[i].isEmpty {
                params[i] = "__\(i)"
            }
        }

        var body = "this.invokeNative(\"\(name)\", ["
        var isPromise = false
        for a in params {
            if a != "_Promise" {
                body += "\n        \(a),"
            } else {
                assert(!isPromise)
                isPromise = true
                body += "\n        [resolve, reject],"
            }
        }
        if params.count > 0 {
            body.removeAtIndex(body.endIndex.predecessor())
        }
        body += "\n    ]);"
        if isPromise {
            body = "\n    ".join(body.componentsSeparatedByString("\n"))
            body = "var _this = this;\n    return new Promise(function(resolve, reject) {\n        _" + body + "\n    });"
        }
        return "function(" + ", ".join(params) + ") {\n    \(body)\n}"
    }
}
