//
//  PresentationExtension.swift
//  PresentationExtension
//
//  Created by Jonathan Dong on 11/11/14.
//  Copyright (c) 2014 Crosswalk. All rights reserved.
//

import Foundation
import CrosswalkLite
import WebKit

public class PresentationExtension: XWalkExtension {

    var remoteWindows: Array<UIWindow> = []
    var remoteViewController: RemoteViewController?

    override init() {
        super.init()
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "screenDidConnect", name: UIScreenDidConnectNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "screenDidDisconnect", name: UIScreenDidDisconnectNotification, object: nil)
    }

    func createWindowForScreen(screen: UIScreen) -> UIWindow {
        var window: UIWindow? = nil
        for win in remoteWindows {
            if win.screen == screen {
                window = win
            }
        }
        if window == nil {
            window = UIWindow(frame: screen.bounds)
            window?.screen = screen
            self.remoteWindows.append(window!)
        }
        return window!
    }

    func addViewControllerToWindow(controller: UIViewController, window: UIWindow) {
        window.rootViewController = controller
        window.hidden = false
    }

    func screenDidConnect(notification: NSNotification) {
        if let screen = notification.object as? UIScreen {
            println("screenDidConnect")
    /*
            var window = createWindowForScreen(screen)
            var viewController = RemoteViewController()
            addViewControllerToWindow(viewController, window: window)
    */
        }
    }

    func screenDidDisconnect(notification: NSNotification) {
        if let screen = notification.object as? UIScreen {
            println("screenDidDisconnect")
    /*
            for var i = 0; i < remoteWindows.count; ++i {
                if remoteWindows[i].screen == screen {
                    remoteWindows.removeAtIndex(i)
                    return
                }
            }
    */
        }
    }

    func js_requestShow(requestId: NSNumber, url: String, baseUrl: String) {
        println("js_requestShow called, with requestId:\(requestId), url:\(url), baseUrl:\(baseUrl)")

        var screens = UIScreen.screens()
        /*
        for obj in screens {
            var window = createWindowForScreen(obj as UIScreen)
            var viewController = RemoteViewController(baseUrl: baseUrl, url: url)
            addViewControllerToWindow(viewController, window: window)
        }
*/
        var screen: UIScreen = UIScreen.screens()[1] as UIScreen
        var window = createWindowForScreen(screen)
        var controller = RemoteViewController()
        addViewControllerToWindow(controller, window: window)

        controller.loadURL(NSURL(string: baseUrl.stringByAppendingPathComponent(url))!)
        self.remoteViewController = controller

        var event = [
            "type": "ShowSucceeded",
            "requestId": requestId,
            "data": 1
        ]
        super.invokeJavaScript(".dispatchEvent", arguments: [event])
    }

    func js_postMessage(viewId: NSNumber, message: String, scope: String) {
        println("js_postMessage with viewId:\(viewId), message:\(message), scope:\(scope)")
        remoteViewController?.sendMessage(message)
    }

    func js_close(viewId: NSNumber) {
    }

}