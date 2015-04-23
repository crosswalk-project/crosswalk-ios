// Copyright (c) 2014 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation

@objc public class XWalkExtensionFactory {
    private struct XWalkExtensionProvider {
        let bundle: NSBundle
        let className: String
    }
    private var extensions: Dictionary<String, XWalkExtensionProvider> = [:]
    private class var singleton : XWalkExtensionFactory {
        struct single {
            static let instance : XWalkExtensionFactory = XWalkExtensionFactory(path: nil)
        }
        return single.instance
    }

    private init() {
        register("Extension.load",  cls: XWalkExtensionLoader.self)
    }
    private convenience init(path: String?) {
        self.init()
        if let dir = path ?? NSBundle.mainBundle().privateFrameworksPath {
            self.scan(dir)
        }
    }

    private func scan(path: String) -> Bool {
        let fm = NSFileManager.defaultManager()
        if fm.fileExistsAtPath(path) == true {
            for i in fm.contentsOfDirectoryAtPath(path, error: nil)! {
                let name = i as! String
                if name.pathExtension == "framework" {
                    let bundlePath = path.stringByAppendingPathComponent(name)
                    if let bundle = NSBundle(path: bundlePath) {
                        scanBundle(bundle)
                    }
                }
            }
            return true
        }
        return false
    }

    private func scanBundle(bundle: NSBundle) -> Bool {
        if let info = bundle.objectForInfoDictionaryKey("XWalkExtensions") as? NSDictionary {
            let e = info.keyEnumerator()
            while let name = e.nextObject() as? String {
                if let className = info[name] as? String {
                    if extensions[name] == nil {
                        extensions[name] = XWalkExtensionProvider(bundle: bundle, className: className)
                    } else {
                        println("WARNING: duplicated extension name '\(name)'")
                    }
                } else {
                    println("WARNING: bad class name '\(info[name])'")
                }
            }
            return true
        }
        return false
    }

    private func register(name: String, cls: AnyClass) -> Bool {
        if extensions[name] == nil {
            let bundle = NSBundle(forClass: cls)
            var className = cls.description()
            className = className.pathExtension.isEmpty ? className : className.pathExtension
            extensions[name] = XWalkExtensionProvider(bundle: bundle, className: className)
            return true
        }
        return false
    }

    private func getClass(name: String) -> AnyClass? {
        if let src = extensions[name] {
            // Load bundle
            if !src.bundle.loaded {
                var error : NSErrorPointer = nil
                if !src.bundle.loadAndReturnError(error) {
                    println("ERROR: Can't load bundle '\(src.bundle.bundlePath)'")
                    return nil
                }
            }

            var classType: AnyClass? = src.bundle.classNamed(src.className)
            if classType != nil {
                // FIXME: Never reach here because the bundle in build directory was loaded in simulator.
                return classType
            }
            // FIXME: workaround the problem
            // Try to get the class with the barely class name (for objective-c written class)
            classType = NSClassFromString(src.className)
            if classType == nil {
                // Try to get the class with its framework name as prefix (for swift written class)
                let classNameWithBundlePrefix = (src.bundle.executablePath?.lastPathComponent)! + "." + src.className
                classType = NSClassFromString(classNameWithBundlePrefix)
            }
            if classType == nil {
                println("ERROR: Failed to get class:'\(src.className)' from bundle:'\(src.bundle.bundlePath)'")
                return nil;
            }
            return classType
        }
        println("ERROR: There's no class named:'\(name)' registered as extension")
        return nil
    }

    private func createExtension(name: String, initializer: Selector, arguments: [AnyObject]) -> AnyObject? {
        if let cls: AnyClass = getClass(name) {
            if class_respondsToSelector(cls, initializer) {
                if method_getNumberOfArguments(class_getInstanceMethod(cls, initializer)) <= UInt32(arguments.count) + 2 {
                    return XWalkInvocation.construct(cls, initializer: initializer, arguments: arguments)
                }
                println("ERROR: Too few arguments to initializer '\(initializer.description)'.")
            } else {
                println("ERROR: Initializer '\(initializer.description)' not found in class '\(cls.description())'.")
            }
        } else {
            println("ERROR: Extension '\(name)' not found")
        }
        return nil
    }

    public class func register(name: String, cls: AnyClass) -> Bool {
        return XWalkExtensionFactory.singleton.register(name, cls: cls)
    }
    public class func createExtension(name: String) -> AnyObject? {
        return XWalkExtensionFactory.singleton.createExtension(name, initializer: "init", arguments: [])
    }
    public class func createExtension(name: String, initializer: Selector, arguments: [AnyObject]) -> AnyObject? {
        return XWalkExtensionFactory.singleton.createExtension(name, initializer: initializer, arguments: arguments)
    }
    public class func createExtension(name: String, initializer: Selector, varargs: AnyObject...) -> AnyObject? {
        return XWalkExtensionFactory.singleton.createExtension(name, initializer: initializer, arguments: varargs)
    }
}
