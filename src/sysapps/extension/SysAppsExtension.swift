// Copyright (c) 2014 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import UIKit
import CrosswalkLite
import WebKit

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

public class SysAppsExtension: XWalkExtension {
    public func getCPUInfo(asyncCallId: NSNumber, callback: NSNumber) {
        var processInfo = NSProcessInfo.processInfo()
        var data: Dictionary<String, AnyObject> = [
            "archName" : processInfo.operatingSystemVersionString,
            "numOfProcessors" : processInfo.processorCount,
            "load" : Double(sysinfoCpuUsage()) / 100
        ]
        sendMessageToJS(asyncCallId, message: data, callback: callback)
    }

    public func getMemoryInfo(asyncCallId: NSNumber, callback: NSNumber) {
        var data = [
            "capacity" : Int(NSProcessInfo.processInfo().physicalMemory),
            "availCapacity" : sysinfoFreeMemory()
        ]
        sendMessageToJS(asyncCallId, message: data, callback: callback)
    }

    public func getStorageInfo(asyncCallId: NSNumber, callback: NSNumber) {
        var (totalSpace, freeSpace) = getDiskSpace()
        var data = [ "storages" : [
            ["name":"localDisk", "id":0, "type":"HSFX", "capacity":totalSpace, "availCapacity":freeSpace]
        ]]
        sendMessageToJS(asyncCallId, message: data, callback: callback)
    }

    public func getDisplayInfo(asyncCallId: NSNumber, callback: NSNumber) {
        var screenBounds = UIScreen.mainScreen().bounds
        var data = [ "displays" : [
            ["name":"localDisplay", "id":0, "isPrimary":true, "isInternal":true, "availWidth":screenBounds.size.width * 2, "availHeight":screenBounds.size.height * 2]
        ]]
        sendMessageToJS(asyncCallId, message: data, callback: callback)
    }

    func sendMessageToJS(asyncCallId: NSNumber, message: Dictionary<String, AnyObject>, callback: NSNumber) {
        var dictionary = [
            "asyncCallId" : asyncCallId,
            "data" : message
        ]
        invokeCallback(callback.intValue, key: nil, arguments: [dictionary])
    }
}
