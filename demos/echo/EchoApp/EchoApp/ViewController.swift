//
//  ViewController.swift
//  EchoApp
//
//  Created by Jonathan Dong on 14/9/23.
//  Copyright (c) 2014年 Crosswalk. All rights reserved.
//

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

