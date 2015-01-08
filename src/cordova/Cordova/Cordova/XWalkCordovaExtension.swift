// Copyright (c) 2014 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import CrosswalkLite

class XWalkCordovaExtension: XWalkExtension, CommandQueueDelegate, CDVCommandDelegate {
    var settings: [NSObject:AnyObject] = [:]
    var plugins: Dictionary<String, CDVPlugin> = [:]
    var commandQueue: CommandQueue = CommandQueue()
    lazy var callbackIdPattern: NSRegularExpression = NSRegularExpression(pattern: "[^A-Za-z0-9._-]", options: NSRegularExpressionOptions.allZeros, error: nil)!

    override func didBindExtension(channel: XWalkChannel, instance: Int) {
        super.didBindExtension(channel, instance:instance)
        commandQueue.delegate = self
        scanForPlugins()
    }

    func scanForPlugins() {
        if let pluginInfoArray = NSBundle.mainBundle().objectForInfoDictionaryKey("CordovaPlugins") as? NSArray {
            for obj in pluginInfoArray {
                var pluginInfo: Dictionary<String, AnyObject> = obj as Dictionary
                let inv = Invocation(name: pluginInfo["className"] as? String)
                inv.appendArgument("webView", value: self.channel.webView)
                if let plugin = inv.construct() as? CDVPlugin {
                    registerPlugin(plugin, className: pluginInfo["name"] as String)
                }
            }
        }
    }

    func registerPlugin(plugin: CDVPlugin, className: String) {
        plugin.commandDelegate = self
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

    func isValidCallbackId(callbackId: String) -> Bool {
        let stringLength = countElements(callbackId)
        // Disallow if too long or if any invalid characters were found.
        if stringLength > 100 {
            return false
        } else if let i = callbackIdPattern.firstMatchInString(callbackId, options: NSMatchingOptions.allZeros, range: NSMakeRange(0, stringLength)) {
            return false
        }
        return true
    }

/// CommandQueueDelegate Impl
    func getPluginInstance(className: String) -> CDVPlugin? {
        if let plugin = plugins[className.lowercaseString] {
            return plugin
        } else {
            println("Failed to find registered plugin by class name:\(className)")
        }
        return nil
    }

/// CDVCommandDelegate Impl
    func pathForResource(resourcepath: String!) -> String! {
        // TODO: (jondong) To be implemented when needed
        return ""
    }


    func getCommandInstance(pluginName: String!) -> AnyObject! {
        // TODO: (jondong) To be implemented when needed
        return NSObject()
    }

    func sendPluginResult(result: CDVPluginResult!, callbackId: String!) {
        if callbackId == "INVALID" {
            return
        }
        if !self.isValidCallbackId(callbackId) {
            println("Invalid callback id received by sendPluginResult")
            return
        }
        var js = "cordova.require('cordova/exec').nativeCallback('\(callbackId)', \(result.status.intValue), \(result.argumentsAsJSON()), \(result.keepCallback.boolValue))"

        self.channel.evaluateJavaScript(js, completionHandler:nil)
    }

    func evalJs(js: String!) {
        evalJs(js, scheduledOnRunLoop: true)
    }

    func evalJs(js: String!, scheduledOnRunLoop: Bool) {
        var message = "cordova.require('cordova/exec').nativeEvalAndFetch(function(){\(js)})"
        self.channel.evaluateJavaScript(message, completionHandler:nil)
    }

    func runInBackground(block: dispatch_block_t!) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), block)
    }

    func userAgent() -> String! {
        // TODO: (jondong) To be implemented when needed
        return ""
    }

    func URLIsWhitelisted(url: NSURL!) -> Bool {
        // TODO: (jondong) To be implemented when needed
        return true
    }
}
