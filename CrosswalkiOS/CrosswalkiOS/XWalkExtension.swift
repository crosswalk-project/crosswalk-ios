//
//  XWalkExtension.swift
//  CrosswalkiOS
//
//  Created by Jonathan Dong on 14/9/24.
//  Copyright (c) 2014年 Crosswalk. All rights reserved.
//

import Foundation

protocol XWalkExtensionDelegate {
    func onPostMessageToJS(e: XWalkExtension, message: String)
    func onBroadcastMessageToJS(e: XWalkExtension, message: String)
}

public class XWalkExtension: NSObject {
    public final var name: String = ""
    final var jsAPI: String = ""
    final var delegate: XWalkExtensionDelegate?

    public func broadcastMessage(message: String) {
        delegate?.onBroadcastMessageToJS(self, message: message)
    }

    public func postMessage(message: String) {
        delegate?.onPostMessageToJS(self, message: message)
    }

    public func onMessage(message: String) {
        assert(false, "XWalkExtension::onMessage should never get called directly. Override it in subclass please.")
    }
}
