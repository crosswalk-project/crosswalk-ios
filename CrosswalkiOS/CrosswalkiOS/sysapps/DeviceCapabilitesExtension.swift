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

func getDiskSpace() -> (totalSpace:Int, totalFreeSpace:Int) {
    var totalSpace: Int = 0
    var totalFreeSpace: Int = 0
    var error: NSError?
    var paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
    if let dictionary = NSFileManager.defaultManager().attributesOfFileSystemForPath(paths.last as String, error: &error) {
        var fileSystemSizeInBytes = dictionary[NSFileSystemSize] as? NSNumber
        var freeFileSystemSizeInBytes = dictionary[NSFileSystemFreeSize] as? NSNumber
        totalSpace = fileSystemSizeInBytes!.integerValue
        totalFreeSpace = freeFileSystemSizeInBytes!.integerValue
    }
    return (totalSpace, totalFreeSpace)
}

class DeviceCapabilitesExtensionInstance: XWalkExtensionInstance {
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
        var processInfo = NSProcessInfo.processInfo()
        return [
            "archName":processInfo.operatingSystemVersionString,
            "numOfProcessors":processInfo.processorCount,
            "load":Double(sysinfoCpuUsage()) / 100
        ]
    }

    func getMemoryInfo() -> Dictionary<String, AnyObject> {
        return [
            "capacity" : Int(NSProcessInfo.processInfo().physicalMemory),
            "availCapacity" : sysinfoFreeMemory()
        ]
    }

    func getStorageInfo() -> Dictionary<String, AnyObject> {
        var (totalSpace:Int, freeSpace:Int) = getDiskSpace()
        return [ "storages" : [
            ["name":"localDisk", "id":0, "type":"HSFX", "capacity":totalSpace, "availCapacity":freeSpace]
        ]]
    }

    func getDisplayInfo() -> Dictionary<String, AnyObject> {
        var screenBounds = UIScreen.mainScreen().bounds
        return [ "displays" : [
            ["name":"localDisplay", "id":0, "isPrimary":true, "isInternal":true, "availWidth":screenBounds.size.width * 2, "availHeight":screenBounds.size.height * 2]
        ]]
    }
}
