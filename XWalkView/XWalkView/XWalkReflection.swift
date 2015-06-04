// Copyright (c) 2014 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation

@objc public class XWalkReflection {
    private enum MemberType: UInt {
        case Method = 1
        case Getter
        case Setter
        case Constructor
    }
    private struct MemberInfo {
        init(cls: AnyClass) {
            self.cls = cls
        }
        init(cls: AnyClass, method: Method) {
            self.cls = cls
            self.method = method
        }
        init(cls: AnyClass, getter: Method, setter: Method) {
            self.cls = cls
            self.getter = getter
            self.setter = setter
        }
        var cls: AnyClass
        var method: Method = nil
        var getter: Method = nil
        var setter: Method = nil
    }

    public let cls: AnyClass
    private var members: [String: MemberInfo] = [:]
    private var ctor: Method = nil

    private let methodPrefix = "jsfunc_"
    private let getterPrefix = "jsprop_"
    private let setterPrefix = "setJsprop_"
    private let ctorPrefix = "initFromJavaScript:"

    public init(cls: AnyClass) {
        self.cls = cls
        enumerate({(name, type, method, cls) -> Bool in
            if type == MemberType.Method {
                assert(self.members[name] == nil, "ambiguous method: \(name)")
                self.members[name] = MemberInfo(cls: cls, method: method)
            } else if type == MemberType.Constructor {
                assert(self.ctor == Method(), "ambiguous initializer")
                self.ctor = method
            } else {
                if self.members[name] == nil {
                    self.members[name] = MemberInfo(cls: cls)
                } else {
                    assert(self.members[name]!.method == Method(), "name conflict: \(name)")
                }
                if type == MemberType.Getter {
                    self.members[name]!.getter = method
                } else {
                    assert(type == MemberType.Setter)
                    self.members[name]!.setter = method
                }
            }
            return true
        })
    }

    // Basic information
    public var allMembers: [String] {
        return members.keys.array
    }
    public var allMethods: [String] {
        return filter(members.keys.array, {(e)->Bool in return self.hasMethod(e)})
    }
    public var allProperties: [String] {
        return filter(members.keys.array, {(e)->Bool in return self.hasProperty(e)})
    }
    public func hasMember(name: String) -> Bool {
        return members[name] != nil
    }
    public func hasMethod(name: String) -> Bool {
        return (members[name]?.method ?? Method()) != Method()
    }
    public func hasProperty(name: String) -> Bool {
        return (members[name]?.getter ?? Method()) != Method()
    }
    public func isReadonly(name: String) -> Bool {
        assert(hasProperty(name))
        return (members[name]?.setter ?? Method()) == Method()
    }

    // Fetching selectors
    public var constructor: Selector {
        return method_getName(ctor)
    }
    public func getMethod(name: String) -> Selector {
        return method_getName(members[name]?.method ?? Method())
    }
    public func getGetter(name: String) -> Selector {
        return method_getName(members[name]?.getter ?? Method())
    }
    public func getSetter(name: String) -> Selector {
        return method_getName(members[name]?.setter ?? Method())
    }

    // TODO: enumerate instance methods of super class
    private func enumerate(callback: ((String, MemberType, Method, AnyClass)->Bool)) -> Bool {
        let methodList = class_copyMethodList(cls, nil);
        for var mlist = methodList; mlist.memory != nil; mlist = mlist.successor() {
            let name = method_getName(mlist.memory).description
            let num = method_getNumberOfArguments(mlist.memory)
            var type: MemberType
            var start: String.Index
            var end: String.Index
            if name.hasPrefix(methodPrefix) && num >= 3 {
                type = MemberType.Method
                start = advance(name.startIndex, 7)
                end = start.successor()
                while name[end] != Character(":") {
                    end = end.successor()
                }
            } else if name.hasPrefix(getterPrefix) && num == 2 {
                type = MemberType.Getter
                start = advance(name.startIndex, 7)
                end = name.endIndex
            } else if name.hasPrefix(setterPrefix) && num == 3 {
                type = MemberType.Setter
                start = advance(name.startIndex, 10)
                end = name.endIndex.predecessor()
            } else if name.hasPrefix(ctorPrefix) {
                type = MemberType.Constructor
                start = name.startIndex
                end = advance(start, 4)
            } else {
                continue
            }
            if !callback(name[start..<end], type, mlist.memory, cls) {
                free(methodList)
                return false
            }
        }
        free(methodList)
        return true
    }
}
