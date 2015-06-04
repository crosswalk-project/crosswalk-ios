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
                    value = toJSONString(val)
                }
                stub += "Extension.defineProperty(exports, '\(name)', \(value), \(!mirror.isReadonly(name)));\n"
            }
        }
        if let script = userDefinedJavaScript() {
            stub += script
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

    private func userDefinedJavaScript() -> String? {
        var className = NSStringFromClass(self.mirror.cls)
        if (className == nil) {
            return nil
        }

        if count(className.pathExtension) > 0 {
            className = className.pathExtension
        }
        var bundle = NSBundle(forClass: self.mirror.cls)
        if let path = bundle.pathForResource(className, ofType: "js") {
            if let content = String(contentsOfFile: path, encoding: NSUTF8StringEncoding, error: nil) {
                return content
            }
        }
        return nil
    }
}

private extension NSNumber {
    var isBool: Bool {
        get {
            return CFGetTypeID(self) == CFBooleanGetTypeID()
        }
    }
}

private func toJSONString(object: AnyObject, isPretty: Bool=false) -> String {
    switch object {
    case is NSNull:
        return "null"
    case is NSError:
        return "\(object)"
    case let number as NSNumber:
        if number.isBool {
            return (number as Bool).description
        } else {
            return (number as NSNumber).stringValue
        }
    case is NSString:
        return "'\(object as! String)'"
    default:
        if let data = NSJSONSerialization.dataWithJSONObject(object,
            options: isPretty ? NSJSONWritingOptions.PrettyPrinted : nil,
            error: nil) as NSData? {
                if let string = NSString(data: data, encoding: NSUTF8StringEncoding) {
                    return string as String
                }
        }
        println("ERROR: Failed to convert object \(object) to JSON string")
        return ""
    }
}
