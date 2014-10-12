// Copyright (c) 2014 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import UIKit
import CrosswalkiOS

class ViewController: XWalkViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        loadExtensionsByBundleNames(["EchoExtension"])

        if let path = NSBundle.mainBundle().pathForResource("echo", ofType: "html") {
            loadURL(NSURL.fileURLWithPath(path)!)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

