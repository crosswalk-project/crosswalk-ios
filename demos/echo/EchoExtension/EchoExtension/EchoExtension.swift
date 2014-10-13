// Copyright (c) 2014 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import CrosswalkiOS

public class EchoExtension: XWalkExtension {
    let prefix = "Echo from native: "

    public override func onMessage(message: String) {
        super.postMessage(prefix + message)
    }
}
