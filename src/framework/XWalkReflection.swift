// Copyright (c) 2014 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation

class XWalkReflection {
    private enum MemberType: UInt {
        case Method = 1
        case Getter
        case Setter
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
        var method: Method? = nil
        var getter: Method? = nil
        var setter: Method? = nil
    }

    private let cls: AnyClass
    private var members: [String: MemberInfo] = [:]

    private let methodPrefix = "jsfunc_"
    private let getterPrefix = "jsprop_"
    private let setterPrefix = "setJsprop_"

    init(cls: AnyClass) {
        self.cls = cls
        enumerate({(name, type, method, cls) -> Bool in
            if type == XWalkReflection.MemberType.Method {
                assert(self.members[name] == nil, "ambiguous method: \(name)")
                self.members[name] = MemberInfo(cls: cls, method: method)
            } else {
                assert(self.members[name]?.method == nil, "name conflict: \(name)")
                if self.members.indexForKey(name) == nil {
                    self.members[name] = MemberInfo(cls: cls)
                }
                if type == XWalkReflection.MemberType.Getter {
                    self.members[name]!.getter = method
                } else {
                    self.members[name]!.setter = method
                }
            }
            return true
        })
    }

    // Basic information
    var allMembers: [String] {
        return members.keys.array
    }
    func hasMember(name: String) -> Bool {
        return members[name] != nil
    }
    func hasMethod(name: String) -> Bool {
        return members[name]?.method != nil
    }
    func hasProperty(name: String) -> Bool {
        return members[name]?.getter != nil
    }
    func isReadonly(name: String) -> Bool? {
        if members[name]?.setter != nil {
            return false
        } else if members[name]?.getter != nil {
            return true
        } else {
            return nil
        }
    }

    // Fetching selectors
    func getMethod(name: String) -> Selector? {
        if let method = members[name]?.method {
            return method_getName(method)
        }
        return nil
    }
    func getGetter(name: String) -> Selector? {
        if let method = members[name]?.getter {
            return method_getName(method)
        }
        return nil
    }
    func getSetter(name: String) -> Selector? {
        if let method = members[name]?.setter {
            return method_getName(method)
        }
        return nil
    }

    // TODO: enumerate instance methods of super class
    private func enumerate(callback: ((String, MemberType, Method, AnyClass)->Bool)) -> Bool {
        for var mlist = class_copyMethodList(cls, nil); mlist.memory != nil; mlist = mlist.successor() {
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
            } else {
                continue
            }
            if !callback(name[start..<end], type, mlist.memory, cls) {
                return false
            }
        }
        return true
    }
}
