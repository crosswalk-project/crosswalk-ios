//
//  EchoExtension.swift
//  EchoExtension
//
//  Created by Jonathan Dong on 14/9/24.
//  Copyright (c) 2014年 Crosswalk. All rights reserved.
//

import CrosswalkiOS

public class EchoExtension: XWalkExtension {
    let prefix = "Echo from native: "

    public override func onMessage(message: String) {
        super.postMessage(prefix + message)
    }
}
