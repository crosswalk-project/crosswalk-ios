// Copyright (c) 2014 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation

public class XWalkExtension: NSObject {
    public final var name: String = ""
    public final var jsAPI: String = ""

    public func createInstance() -> XWalkExtensionInstance? {
        assert(false, "XWalkExtension::createInstance should never get called directly. Override it in subclass please.")
        return nil
    }
}

protocol XWalkExtensionInstanceDelegate {
    func onPostMessageToJS(instance: XWalkExtensionInstance, message: String)
    func onBroadcastMessageToJS(instance: XWalkExtensionInstance, message: String)
}

public class XWalkExtensionInstance: NSObject {
    struct UniqueIDWrapper {
        static var uniqueID: Int = 0
    }

    public final let id: Int = UniqueIDWrapper.uniqueID++
    final var delegate: XWalkExtensionInstanceDelegate?

    public func broadcastMessage(message: String) {
        delegate?.onBroadcastMessageToJS(self, message: message)
    }

    public func postMessage(message: String) {
        delegate?.onPostMessageToJS(self, message: message)
    }

    public func onMessage(message: String) {
        assert(false, "XWalkExtensionInstance::onMessage should never get called directly. Override it in subclass please.")
    }
}
