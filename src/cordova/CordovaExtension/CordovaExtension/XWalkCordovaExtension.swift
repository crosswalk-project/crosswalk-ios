// Copyright (c) 2014 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import CrosswalkLite
import SwiftyJSON

class XWalkCordovaExtension: XWalkExtension, CommandQueueDelegate {
    var plugins: Dictionary<String, CDVPlugin> = [:]
    var commandQueue: CommandQueue

    override init() {
        commandQueue = CommandQueue()
        super.init()
        commandQueue.delegate = self
        scanForPlugins()
    }

    convenience init(param: AnyObject) {
        self.init()
    }

    func scanForPlugins() {
        if let pluginInfoArray = NSBundle.mainBundle().objectForInfoDictionaryKey("CordovaPlugins") as? NSArray {
            for obj in pluginInfoArray {
                var pluginInfo: Dictionary<String, AnyObject> = obj as Dictionary
                var pluginType = NSClassFromString(pluginInfo["className"] as? String) as CDVPlugin.Type
                registerPlugin(pluginType(), className: pluginInfo["name"] as String)
            }
        }
    }

    func registerPlugin(plugin: CDVPlugin, className: String) {
        plugins[className.lowercaseString] = plugin
        plugin.pluginInitialize()
    }

    func jsfunc_postToNative(cid: UInt32, message: NSString) -> Bool {
        if message.length == 0 {
            return false
        }
        commandQueue.enqueueCommandBatch(message)
        commandQueue.executePending()
        return true
    }

    func getPluginInstance(className: String) -> CDVPlugin? {
        if let plugin = plugins[className.lowercaseString] {
            return plugin
        } else {
            println("Failed to find registered plugin by class name:\(className)")
        }
        return nil
    }
}
