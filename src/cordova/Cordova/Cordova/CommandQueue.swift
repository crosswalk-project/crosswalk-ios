// Copyright (c) 2014 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation

protocol CommandQueueDelegate : class {
    func getPluginInstance(className: String) -> CDVPlugin?
}

class CommandQueue : NSObject {
    private var queue : Array<CDVInvokedUrlCommand> = []
    weak var delegate : CommandQueueDelegate?

    func enqueueCommandBatch(batchJSON: String) -> Bool {
        if batchJSON.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) == 0 {
            return false
        }

        if let commands: NSArray = batchJSON.JSONObject() as? NSArray {
            for obj in commands {
                if let command: NSArray = obj as? NSArray {
                    queue.append(CDVInvokedUrlCommand(json: command))
                }
            }
            return true
        }
        return false
    }

    func execute(command: CDVInvokedUrlCommand) -> Bool {
        if command.className == nil || command.methodName == nil {
            return false
        }

        if let plugin: CDVPlugin = delegate?.getPluginInstance(command.className) {
            let selector: Selector = NSSelectorFromString("\(command.methodName):")
            if plugin.respondsToSelector(selector) {
                Invocation.call(plugin, selector: selector, arguments: [command])
                return true
            } else {
                println("ERROR: Method \(command.methodName) not defined in plugin: \(command.className)")
            }
        }
        return false
    }

    func executePending() {
        while queue.count > 0 {
            if !self.execute(queue.removeAtIndex(0)) {
                println("Failed to execute command")
            }
        }
    }
}
