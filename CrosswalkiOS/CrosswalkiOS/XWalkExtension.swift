// Copyright (c) 2014 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation
import WebKit

func nameWithoutDot(name: String) -> String {
    return join("", name.componentsSeparatedByString("."))
}

func extensionCodes(name: String) -> String {
    return join("\n", [
        "var extension = (function () {",
        "    var messageListener = null;",
        "    var postMessage = function(msg) {",
        "        if (msg == undefined) {",
        "            return;",
        "        }",
        "        window.webkit.messageHandlers.\(nameWithoutDot(name)).postMessage(msg);",
        "    }",
        "    var setMessageListener = function(callback) {",
        "        if (callback == undefined) {",
        "            return;",
        "        }",
        "        messageListener = callback;",
        "    }",
        "    var invokeMessageListener = function(msg) {",
        "        if (messageListener instanceof Function) {",
        "            messageListener(msg);",
        "        }",
        "    }",
        "    return {",
        "        'postMessage' : postMessage,",
        "        'setMessageListener' : setMessageListener,",
        "        'invokeMessageListener' : invokeMessageListener,",
        "    }",
        "})();"])
}

func codeToEnsureNamespace(extensionName: String) -> String {
    var namespaceArray = extensionName.componentsSeparatedByString(".")
    var namespace: String = ""
    var result: String = ""
    for var i = 0; i < namespaceArray.count; ++i {
        if (countElements(namespace) > 0) {
            namespace += "."
        }
        namespace += namespaceArray[i]
        result += namespace + " = " + namespace + " || {}; "
    }
    return result
}

protocol XWalkExtensionDelegate {
    func onEvaluateJavascript(e: XWalkExtension, jsCode: String)
}

public class XWalkExtension: NSObject, WKScriptMessageHandler, XWalkExtensionInstanceDelegate {
    public final var name: String = ""
    public final var jsAPI: String = ""
    public final var instances = Dictionary<Int, XWalkExtensionInstance>()
    final var delegate: XWalkExtensionDelegate?

    public func createInstance() -> XWalkExtensionInstance? {
        assert(false, "XWalkExtension::createInstance should never get called directly. Override it in subclass please.")
        return nil
    }

    func injectJSCodes(controller: WKUserContentController) {
        let codes = join("\n", [
            "var \(codeToEnsureNamespace(name))",
            "(function() {",
            "    \(extensionCodes(name))",
            "    var exports = {};",
            "    (function() {'use strict'; ",
            "        \(jsAPI)})();",
            "    exports.extension = extension;",
            "    \(name) = exports;",
            "})();"])
        let userScript = WKUserScript(source: codes, injectionTime:
            WKUserScriptInjectionTime.AtDocumentStart, forMainFrameOnly: false)
        controller.addUserScript(userScript)
        controller.addScriptMessageHandler(self, name: nameWithoutDot(name))

        var instance = createInstance()
        instance?.delegate = self
        instances[instance!.id] = instance
    }

    public func userContentController(userContentController: WKUserContentController!,
        didReceiveScriptMessage message: WKScriptMessage!) {
            var msg: String = message.body as String
            for (_, instance) in instances {
                instance.onMessage(msg)
            }
    }

    func onPostMessageToJS(instance: XWalkExtensionInstance, message: String) {
        delegate?.onEvaluateJavascript(self, jsCode: "\(name).extension.invokeMessageListener('\(message)');")
    }
}


protocol XWalkExtensionInstanceDelegate {
    func onPostMessageToJS(instance: XWalkExtensionInstance, message: String)
}

public class XWalkExtensionInstance: NSObject {
    struct UniqueIDWrapper {
        static var uniqueID: Int = 0
    }

    public final let id: Int = UniqueIDWrapper.uniqueID++
    final var delegate: XWalkExtensionInstanceDelegate?

    public func postMessage(message: String) {
        delegate?.onPostMessageToJS(self, message: message)
    }

    public func onMessage(message: String) {
        assert(false, "XWalkExtensionInstance::onMessage should never get called directly. Override it in subclass please.")
    }
}
