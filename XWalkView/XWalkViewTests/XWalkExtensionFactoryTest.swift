// Copyright (c) 2015 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import UIKit
import XCTest
import XWalkView

class DemoExtension : XWalkExtension {
}

class XWalkExtensionFactoryTest: XCTestCase {
    let demoExtensionName = "xwalk.extensionFactory.test.demo"

    override func setUp() {
        super.setUp()
        XWalkExtensionFactory.register(demoExtensionName, cls: DemoExtension.self)
    }

    func testRegister() {
        XCTAssertTrue(XWalkExtensionFactory.register("xwalk.extensionFactory.test.anotherDemo", cls: DemoExtension.self))
        XCTAssertFalse(XWalkExtensionFactory.register(demoExtensionName, cls: DemoExtension.self))
    }

    func testCreateExtension() {
        XCTAssertNotNil(XWalkExtensionFactory.createExtension(demoExtensionName))
    }

}

