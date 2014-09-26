//
//  EchoExtension.swift
//  EchoExtension
//
//  Created by Jonathan Dong on 14/9/24.
//  Copyright (c) 2014年 Crosswalk. All rights reserved.
//

import CrosswalkiOS

class EchoExtension: XWalkExtension {
    let prefix = "Echo from native: "

    override func onMessage(instanceID: Int, message: String) {
        super.postMessage(instanceID, message: prefix + message)
    }
}
