// Copyright (c) 2014 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation

public class XWalkExtensionFactory: NSObject {
    struct XWalkExtensionProvider {
        let bundle: NSBundle
        let className: String
    }
    var extensions: Dictionary<String, XWalkExtensionProvider> = [:]
    public class var singleton : XWalkExtensionFactory {
        struct single {
            static let instance : XWalkExtensionFactory = XWalkExtensionFactory()
        }
        return single.instance
    }

    internal override init() {
        super.init()
        if let path = NSBundle.mainBundle().privateFrameworksPath {
            self.scan(path)
        }
    }
    internal init(path: String) {
        super.init()
        self.scan(path)
    }

    public func scan(path: String) -> Bool {
        let fm = NSFileManager.defaultManager()
        if fm.fileExistsAtPath(path) == true {
            for i in fm.contentsOfDirectoryAtPath(path, error: nil)! {
                let name = i as String
                if name.pathExtension == "framework" {
                    let bundlePath = path.stringByAppendingPathComponent(name)
                    if let bundle = NSBundle(path: bundlePath) {
                        scan(bundle)
                    }
                }
            }
            return true
        }
        return false
    }

    public func scan(bundle: NSBundle) -> Bool {
        if let info = bundle.objectForInfoDictionaryKey("XWalkExtensions") as? NSDictionary {
            let e = info.keyEnumerator()
            while let name = e.nextObject() as? String {
                if let className = info[name] as? String {
                    if (extensions[name] == nil) {
                        extensions[name] = XWalkExtensionProvider(bundle: bundle, className: className)
                    } else {
                        println("WARNING: duplicated extension name '\(name)'")
                    }
                } else {
                    println("WARNING: bad class name '\(info[name])'")
                }
            }
        } else {
            return false
        }
        return true
    }

    public func createExtension(name: String) -> XWalkExtension? {
        if let src = extensions[name] {
            // Load bundle
            if !src.bundle.loaded {
                var error : NSErrorPointer = nil
                if !src.bundle.loadAndReturnError(error) {
                    println("ERROR: Can't load bundle '\(src.bundle.bundlePath)'")
                    return nil
                }
            }

            var className = ""
            if let type: AnyClass = src.bundle.classNamed(src.className) {
                // FIXME: Never reach here because the bundle in build directory was loaded in simulator.
                className = NSStringFromClass(type)
            } else {
                // FIXME: workaround the problem
                className = (src.bundle.executablePath?.lastPathComponent)! + "." + src.className
                //println("ERROR: Class '\(src.className)' not found in bundle '\(src.bundle.bundlePath)")
                //return nil
            }

            if let ext = ObjectFactory<XWalkExtension>.createInstance(
                    className: "\(className)",
                    initializer: "initWithName:",
                    argument: name) {
                return ext
            }
            println("ERROR: Can't create extension '\(name)'")
        } else {
            println("ERROR: Extension '\(name)' not found")
        }
        return nil
    }
}
