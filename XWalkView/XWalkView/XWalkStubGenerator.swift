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
        var stub = "(function(exports) {\n"
        for name in mirror.allMembers {
            if mirror.hasMethod(name) {
                stub += "exports.\(name) = \(generateMethodStub(name))\n"
            } else {
                var value = "undefined"
                if object != nil {
                    // Fetch initial value
                    let result = XWalkInvocation.call(object, selector: mirror.getGetter(name), arguments: nil)
                    var val: AnyObject = (result.isObject ? result.nonretainedObjectValue : result as? NSNumber) ?? NSNull()
                    if val as? String != nil {
                        val = "'\(val)'"
                    }
                    value = JSON(val).toString()
                }
                stub += "Extension.defineProperty(exports, '\(name)', \(value), \(!mirror.isReadonly(name)));\n"
            }
        }
        stub += "\n})(Extension.create(\(channelName), '\(namespace)'"
        if mirror.constructor != nil {
            stub += ", " + generateMethodStub("+", selector: mirror.constructor) + ", true"
        } else if mirror.hasMethod("function") {
            stub += ", function(){return arguments.callee.function.apply(arguments.callee, arguments);}"
        }
        stub += "));\n"
        return stub
    }

    private func generateMethodStub(name: String, selector: Selector? = nil, this: String = "this") -> String {
        var params = (selector ?? mirror.getMethod(name)).description.componentsSeparatedByString(":")
        params.removeAtIndex(0)
        params.removeLast()

        // deal with parameters without external name
        for i in 0..<params.count {
            if params[i].isEmpty {
                params[i] = "__\(i)"
            }
        }

        let isPromise = params.last == "_Promise"
        if isPromise { params.removeLast() }

        let list = ", ".join(params)
        var body = "invokeNative('\(name)', [\(list)"
        if isPromise {
            body = "var _this = \(this);\n    return new Promise(function(resolve, reject) {\n        _this.\(body)"
            body += (list.isEmpty ? "" : ", ") + "{'resolve': resolve, 'reject': reject}]);\n    });"
        } else {
            body = "\(this).\(body)]);"
        }
        return "function(\(list)) {\n    \(body)\n}"
    }
}
