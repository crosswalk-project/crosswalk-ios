// Copyright (c) 2015 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation

public class ExecutionContext: NSObject {
    public var scriptToEvaluate: String
    public let completionHandler: ((AnyObject!, NSError!) -> Void)?

    public init(script: String, completionHandler:((AnyObject!, NSError!) -> Void)?) {
        self.scriptToEvaluate = script
        self.completionHandler = completionHandler
    }
}
