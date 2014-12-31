// Copyright (c) 2014 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation

public class XWalkExtension : NSObject, XWalkDelegate {
    private weak var _channel: XWalkChannel!
    private var _namespace: String = ""

    public final weak var channel: XWalkChannel! { return _channel }
    public final var namespace: String { return _namespace }

    public func didEstablishChannel(channel: XWalkChannel) {
        _channel = channel
    }
    public func didGenerateStub(stub: String) -> String {
        let bundle : NSBundle = NSBundle(forClass: self.dynamicType)
        var name = NSStringFromClass(self.dynamicType)
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
    public func didBindExtension(namespace: String) {
        _namespace = namespace
    }

    internal func setProperty(name: String, value: AnyObject?) {
        // TODO: check type
        var val: AnyObject = value ?? NSNull()
        if val.isKindOfClass(NSString.classForCoder()) {
            val = NSString(format: "'\(val as String)'")
        }
        let json = JSON(val).toString()
        let cmd = "\(namespace).properties['\(name)'] = \(json);"
        evaluateJavaScript(cmd)
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
        var f = function
        var this = "null"
        if f[f.startIndex] == "." {
            // Invoke a method of this object
            f = namespace + function
            this = namespace
        }
        evaluateJavaScript("\(f).apply(\(this), \(JSON(arguments).toString()));")
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
            if let selector = channel.mirror.getGetter(name) {
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
            if let selector = channel.mirror.getSetter(name) {
                if channel.mirror.getOriginalSetter(name) == nil {
                    setProperty(name, value: value)
                }
                Invocation.call(self, selector: selector, arguments: [value ?? NSNull()])
            } else if channel.mirror.hasProperty(name) {
                NSException.raise("PropertyError", format: "Property '%@' is readonly.", arguments: getVaList([name]))
            } else {
                NSException.raise("PropertyError", format: "Property '%@' is not defined.", arguments: getVaList([name]))
            }
        }
    }
}
