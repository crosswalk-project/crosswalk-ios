// Copyright (c) 2014 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import UIKit
import CrosswalkLite

func getDiskSpace() -> (totalSpace:Int, totalFreeSpace:Int) {
    var totalSpace: Int = 0
    var totalFreeSpace: Int = 0
    var error: NSError?
    let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
    if let dictionary = NSFileManager.defaultManager().attributesOfFileSystemForPath(paths.last as String, error: &error) {
        let fileSystemSizeInBytes = dictionary[NSFileSystemSize] as? NSNumber
        let freeFileSystemSizeInBytes = dictionary[NSFileSystemFreeSize] as? NSNumber
        totalSpace = fileSystemSizeInBytes!.integerValue
        totalFreeSpace = freeFileSystemSizeInBytes!.integerValue
    }
    return (totalSpace, totalFreeSpace)
}

class SysAppsExtension: XWalkExtension {
    func jsfunc_getCPUInfo(cid: NSNumber, _Promise: NSNumber) {
        let processInfo = NSProcessInfo.processInfo()
        let data: Dictionary<String, AnyObject> = [
            "archName" : processInfo.operatingSystemVersionString,
            "numOfProcessors" : processInfo.processorCount,
            "load" : Double(sysinfoCpuUsage()) / 100
        ]
        invokeCallback(_Promise.unsignedIntValue, index: 0, arguments: [data])
    }
    func jsfunc_getMemoryInfo(cid: NSNumber, _Promise: NSNumber) {
        let data = [
            "capacity" : Int(NSProcessInfo.processInfo().physicalMemory),
            "availCapacity" : sysinfoFreeMemory()
        ]
        invokeCallback(_Promise.unsignedIntValue, index: 0, arguments: [data])
    }

    func jsfunc_getStorageInfo(cid: NSNumber, _Promise: NSNumber) {
        let (totalSpace, freeSpace) = getDiskSpace()
        let data = [ "storages" : [
            ["name":"localDisk", "id":0, "type":"HSFX", "capacity":totalSpace, "availCapacity":freeSpace]
        ]]
        invokeCallback(_Promise.unsignedIntValue, index: 0, arguments: [data])
    }

    func jsfunc_getDisplayInfo(cid: NSNumber, _Promise: NSNumber) {
        let screenBounds = UIScreen.mainScreen().bounds
        let data = [ "displays" : [
            ["name":"localDisplay", "id":0, "isPrimary":true, "isInternal":true, "availWidth":screenBounds.size.width * 2, "availHeight":screenBounds.size.height * 2]
        ]]
        invokeCallback(_Promise.unsignedIntValue, index: 0, arguments: [data])
    }
}
