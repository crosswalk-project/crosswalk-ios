//
//  XWalkExtension.swift
//  CrosswalkiOS
//
//  Created by Jonathan Dong on 14/9/24.
//  Copyright (c) 2014年 Crosswalk. All rights reserved.
//

import Foundation

public class XWalkExtension {
    let name: String
    let jsAPI: String

    public init(name: String, jsAPI: String) {
        self.name = name
        self.jsAPI = jsAPI
    }

    public func broadcastMessage(message: String) {
        // TODO:(jondong)
    }

    public func postMessage(instanceID: Int, message: String) {
        // TODO:(jondong)
    }

    public func onMessage(instanceID: Int, message: String) {
        // TODO:(jondong)
    }
}
