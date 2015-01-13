// Copyright (c) 2014 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation

public class XWalkExtension : NSObject, XWalkDelegate {
    private weak var _channel: XWalkChannel!
    private var _instance: Int = 0

    public final weak var channel: XWalkChannel! { return _channel }
    public final var instance: Int { return _instance }
    public final var namespace: String { return _channel.namespace }

    public func didGenerateStub(stub: String) -> String {
        let bundle : NSBundle = NSBundle(forClass: self.dynamicType)
        var name = self.dynamicType.description()
        name = name.pathExtension.isEmpty ? name : name.pathExtension
        if let path = bundle.pathForResource(name, ofType: "js") {
            var error: NSError?
            if let content = NSString(contentsOfFile: path, encoding: UInt(NSUTF8StringEncoding), error: &error) {
                return "\(stub)\n\(content)"
            } else {
                NSException.raise("EncodingError", format: "'%@.js' should be UTF-8 encoding.", arguments: getVaList([name]))
            }
        }
        return stub
    }
    public func didBindExtension(channel: XWalkChannel, instance: Int) {
        _channel = channel
        _instance = instance

        if instance != 0 {
            for name in _channel.mirror.allMembers {
                if _channel.mirror.hasProperty(name) {
                    setProperty(name, value: self[name])
                }
            }
        }
    }

    internal func setProperty(name: String, value: AnyObject?) {
        // TODO: check type
        var val: AnyObject = value ?? NSNull()
        if val.isKindOfClass(NSString.classForCoder()) {
            val = NSString(format: "'\(val as String)'")
        }
        let json = JSON(val).toString()
        let script = "\(_channel.namespace)" + (_instance != 0 ? "[\(instance)]" : "") + ".properties['\(name)'] = \(json);"
        evaluateJavaScript(script)
    }
    public func invokeCallback(id: UInt32, key: String? = nil, arguments: [AnyObject] = []) {
        let args = [NSNumber(unsignedInt: id), key ?? NSNull(), arguments]
        invokeJavaScript(".invokeCallback", arguments: args)
    }
    public func invokeCallback(id: UInt32, index: UInt32, arguments: [AnyObject] = []) {
        let args = [NSNumber(unsignedInt: id), NSNumber(unsignedInt: index), arguments]
        invokeJavaScript(".invokeCallback", arguments: args)
    }
    public func releaseArguments(callid: UInt32) {
        invokeJavaScript(".releaseArguments", arguments: [NSNumber(unsignedInt: callid)])
    }
    public func invokeJavaScript(function: String, arguments: [AnyObject] = []) {
        var script = function
        var this = "null"
        if script[script.startIndex] == "." {
            // Invoke a method of this object
            this = _channel.namespace + (_instance != 0 ? "[\(instance)]" : "")
            script = this + function
        }
        script += ".apply(\(this), \(JSON(arguments).toString()));"
        evaluateJavaScript(script)
    }
    public func evaluateJavaScript(string: String) {
        _channel.evaluateJavaScript(string, completionHandler: { (obj, err)->Void in
            if err != nil {
                println("ERROR: Failed to execute script, \(err)\n------------\n\(string)\n------------")
            }
        })
    }
    public func evaluateJavaScript(string: String, onSuccess: ((AnyObject!)->Void)?, onError: ((NSError!)->Void)?) {
        _channel.evaluateJavaScript(string, completionHandler: { (obj, err)->Void in
            err == nil ? onSuccess?(obj) : onError?(err)
            return    // To make compiler happy
        })
    }

    public subscript(name: String) -> AnyObject? {
        get {
            let selector = _channel.mirror.getGetter(name)
            if selector != nil {
                let result = Invocation.call(self, selector: selector, arguments: nil)
                if let obj: AnyObject = result.object ?? result.number {
                    return obj
                } else if !(result.object is NSNull) {
                    NSException.raise("PropertyError", format: "Type of property '%@' is unknown.", arguments: getVaList([name]))
                }
            } else {
                NSException.raise("PropertyError", format: "Property '%@' is not defined.", arguments: getVaList([name]))
            }
            return nil
        }
        set(value) {
            let selector = _channel.mirror.getSetter(name)
            if selector != nil {
                if channel.mirror.getOriginalSetter(name) == nil {
                    setProperty(name, value: value)
                }
                Invocation.call(self, selector: selector, arguments: [value ?? NSNull()])
            } else if _channel.mirror.hasProperty(name) {
                NSException.raise("PropertyError", format: "Property '%@' is readonly.", arguments: getVaList([name]))
            } else {
                NSException.raise("PropertyError", format: "Property '%@' is not defined.", arguments: getVaList([name]))
            }
        }
    }
}
