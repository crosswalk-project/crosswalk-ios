//
//  DeviceCapabilitesExtension.swift
//  CrosswalkiOS
//
//  Created by Jonathan Dong on 14/10/16.
//  Copyright (c) 2014年 Crosswalk. All rights reserved.
//

import UIKit

class DeviceCapabilitesExtension: XWalkExtension {
    override func createInstance() -> XWalkExtensionInstance? {
        return DeviceCapabilitesExtensionInstance()
    }
}

class DeviceCapabilitesExtensionInstance: XWalkExtensionInstance {
    override func onMessage(message: String) {
    }
}
