// Copyright (c) 2014 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import UIKit
import SwiftyJSON
import WebKit

class DeviceCapabilitesExtension: XWalkExtension {
    override func createInstance() -> XWalkExtensionInstance? {
        return DeviceCapabilitesExtensionInstance()
    }
}

class LinearCongruentialGenerator {
    var lastRandom = 42.0
    let m = 139968.0
    let a = 3877.0
    let c = 29573.0
    func random() -> Double {
        lastRandom = ((lastRandom * a + c) % m)
        return lastRandom / m
    }
}

class DeviceCapabilitesExtensionInstance: XWalkExtensionInstance {
    var randomGenerator: LinearCongruentialGenerator = LinearCongruentialGenerator()

    override func onMessage(message: String) {
        var msg = JSON(data: message.dataUsingEncoding(NSUTF8StringEncoding)!)
        var dictionary: Dictionary<String, AnyObject> = [
            "asyncCallId" : msg["asyncCallId"].intValue,
            "data" : self.valueForKey(msg["cmd"].stringValue) as Dictionary<String, AnyObject>
        ]

        var error: NSErrorPointer = NSErrorPointer()
        var jsonData = NSJSONSerialization.dataWithJSONObject(dictionary, options: NSJSONWritingOptions.allZeros, error:error)
        super.postMessage(NSString(data: jsonData!, encoding: NSUTF8StringEncoding))
    }

    func getCPUInfo() -> Dictionary<String, AnyObject> {
        return [
            "archName":"x86_64",
            "numOfProcessors":4,
            "load":randomGenerator.random()
        ]
    }

    func getMemoryInfo() -> Dictionary<String, AnyObject> {
        let capacity: Double = 8 * 1024 * 1024 * 1024
        let availCapacity: Double = capacity * randomGenerator.random()
        return [
            "availCapacity" : availCapacity,
            "capacity" : capacity
        ]
    }

    func getStorageInfo() -> Dictionary<String, AnyObject> {
        let gb: Double = 1024 * 1024 * 1024
        return [ "storages" : [
            ["name":"local", "id":12345, "type":"ext4", "capacity":2 * gb, "availCapacity": 1.5 * gb],
            ["name":"sdcard", "id":54321, "type":"FAT32", "capacity":4 * gb, "availCapacity":0.2 * gb]]
        ]
    }

    func getDisplayInfo() -> Dictionary<String, AnyObject> {
        return [ "displays" : [
            ["name":"local", "id":12345, "isPrimary":true, "isInternal":true, "availWidth":1024, "availHeight":768],
            ["name":"external", "id":54321, "isPrimary":false, "isInternal":false, "availWidth":2048, "availHeight":1440]]
        ]
    }
}
