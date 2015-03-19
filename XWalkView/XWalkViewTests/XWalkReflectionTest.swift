// Copyright (c) 2015 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import UIKit
import XCTest
import XWalkView

class DemoClassForMirrorTest : NSObject {
    var jsprop_normalProperty: String = "normal"
    let jsprop_constProperty: Int = 0

    override init() {
        super.init()
    }

    convenience init(fromJavaScript: String) {
        self.init()
    }

    func jsfunc_demoMethodWithParams(cid: UInt32, name: String, value: AnyObject?) {
    }

    func jsfunc_demoMethod(cid: UInt32) {
    }
}

class XWalkReflectionTest: XCTestCase {
    var mirror: XWalkReflection?
    var testObject: DemoClassForMirrorTest = DemoClassForMirrorTest()

    override func setUp() {
        super.setUp()
        mirror = XWalkReflection(cls: testObject.dynamicType)
    }

    override func tearDown() {
        super.tearDown()
    }

    func testAllMembers() {
        if let allMembers = mirror?.allMembers {
            XCTAssertEqual(allMembers.count, 4)
            XCTAssertTrue(contains(allMembers, "normalProperty"))
            XCTAssertTrue(contains(allMembers, "constProperty"))
            XCTAssertTrue(contains(allMembers, "demoMethodWithParams"))
            XCTAssertTrue(contains(allMembers, "demoMethod"))
        } else {
            XCTFail("Failed in testAllMembers")
        }
    }

    func testAllMethods() {
        if let allMethods = mirror?.allMethods {
            XCTAssertEqual(allMethods.count, 2)
            XCTAssertTrue(contains(allMethods, "demoMethodWithParams"))
            XCTAssertTrue(contains(allMethods, "demoMethod"))
        } else {
            XCTFail("Failed in testAllMethods")
        }
    }

    func testAllProperties() {
        if let allProperties = mirror?.allProperties {
            XCTAssertEqual(allProperties.count, 2)
            XCTAssertTrue(contains(allProperties, "normalProperty"))
            XCTAssertTrue(contains(allProperties, "constProperty"))
        } else {
            XCTFail("Failed in testAllProperties")
        }
    }

    func testHasMember() {
        XCTAssertTrue(mirror!.hasMember("normalProperty"))
        XCTAssertTrue(mirror!.hasMember("constProperty"))
        XCTAssertTrue(mirror!.hasMember("demoMethodWithParams"))
        XCTAssertTrue(mirror!.hasMember("demoMethod"))
        XCTAssertFalse(mirror!.hasMember("nonExistingMember"))
    }

    func testHasMethod() {
        XCTAssertTrue(mirror!.hasMethod("demoMethodWithParams"))
        XCTAssertTrue(mirror!.hasMethod("demoMethod"))
        XCTAssertFalse(mirror!.hasMethod("nonExistingMethod"))
    }

    func testHasProperty() {
        XCTAssertTrue(mirror!.hasProperty("normalProperty"))
        XCTAssertTrue(mirror!.hasProperty("constProperty"))
        XCTAssertFalse(mirror!.hasProperty("nonExistingProperty"))
    }

    func testIsReadonly() {
        XCTAssertTrue(mirror!.isReadonly("constProperty"))
        XCTAssertFalse(mirror!.isReadonly("normalProperty"))
    }

    func testConstructor() {
        XCTAssertEqual(mirror!.constructor, Selector("initFromJavaScript:"))
        XCTAssertNotEqual(mirror!.constructor, Selector("init"))
    }

    func testGetMethod() {
        XCTAssertEqual(mirror!.getMethod("demoMethodWithParams"), Selector("jsfunc_demoMethodWithParams:name:value:"))
        XCTAssertEqual(mirror!.getMethod("demoMethod"), Selector("jsfunc_demoMethod:"))
        XCTAssertNotEqual(mirror!.getMethod("nonExistMethod"), Selector("jsfunc_demoMethod:"))
        XCTAssertNotEqual(mirror!.getMethod("demoMethod"), Selector("jsfunc_nonExistMethod:"))
    }

    func testGetGetter() {
        XCTAssertEqual(mirror!.getGetter("normalProperty"), Selector("jsprop_normalProperty"))
        XCTAssertEqual(mirror!.getGetter("constProperty"), Selector("jsprop_constProperty"))
        XCTAssertNotEqual(mirror!.getGetter("nonExistGetter"), Selector("jsprop_normalProperty"))
        XCTAssertNotEqual(mirror!.getGetter("constProperty"), Selector("jsprop_nonExistProperty"))
    }

    func testGetSetter() {
        XCTAssertEqual(mirror!.getSetter("normalProperty"), Selector("setJsprop_normalProperty:"))
        XCTAssertNotEqual(mirror!.getSetter("normalProperty"), Selector("setJsprop_constProperty:"))
        XCTAssertNotEqual(mirror!.getGetter("nonExistSetter"), Selector("setJsprop_normalProperty:"))
        XCTAssertNotEqual(mirror!.getGetter("normalProperty"), Selector("setJsprop_nonExistProperty:"))
    }

}

