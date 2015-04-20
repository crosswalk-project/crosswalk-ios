# Crosswalk Project for iOS

## Introduction
Crosswalk Project for iOS is a sub-project of [Crosswalk](https://crosswalk-project.org/), it aims to provide a web runtime to develop sophisticated iOS native or hybrid applications.

[![Build Status](https://travis-ci.org/crosswalk-project/crosswalk-ios.svg?branch=master)](https://travis-ci.org/crosswalk-project/crosswalk-ios)


* Extended WKWebView

  Crosswalk Project for iOS is built on top of `WKWebView`, the mordern WebKit framework debuted in iOS 8.0. We extend the WKWebView to build Crosswalk extension framework within, and we are intended to bring the least intrusion to the interface to make developers use it as natural as WKWebView itself. For the detailed information you may refer to [Embedding Mode & WKWebView](https://github.com/crosswalk-project/crosswalk-ios/wiki/Embedding-Mode-&-Native-APIs).

* Crosswalk Extension Framework

  Extension is a way to extend the ability of Crosswalk runtime. You can write your functionalities in both Swift and Objective-C codes and expose it as a JavaScript function or object. All JavaScript stub codes can be generated automatically under the hood based on the native interface. For more information please refer to [Crosswalk Extension](https://github.com/crosswalk-project/crosswalk-ios/wiki/Extensions).

* Cordova Plugins Support

  To leverage existing Cordova plugins, a Cordova extension is provided to simulate Cordova environment. You only need to place source files of Cordova plugins into your project and register the classes of plugins in the manifest. For more information please refer to [Cordova Plugins Support](https://github.com/crosswalk-project/crosswalk-ios/wiki/Cordova-Plugin-Support).

## System Requirement
Development:
* iOS SDK 8+
* Xcode 6+

Deployment:
* iOS 8+

## Quickstart
Here we'd like to show you the quick demo to setup a native application with Crosswalk extension support.

1. Setup The Working Directory

  * Create a working directory called `EchoDemo` in a suitable place, then `cd EchoDemo`;

  * Clone the `crosswalk-ios` project with command:

    `git clone https://github.com/crosswalk-project/crosswalk-ios.git`

  * Initialize the `crosswalk-ios` submodules with commands:

    ```bash
      cd crosswalk-ios
      git submodule update --init --recursive
      cd -
    ```

2. Create The Application Project

  * Create an iOS application project called `Echo` with the "Single View Application" template in the working directory, and use language "Swift" for convenience.

  * Add `XWalkView` project into the `Echo` project.

    In `File` -> `Add Files to "Echo"...`, choose the `XWalkView.xcodeproj` from `crosswalk-ios/XWalkView/XWalkView.xcodeproj`;

  * Link `XWalkView` into `Echo` target.

    Select `Echo` target in `Echo` project, in `General` -> `Linked Frameworks and Libraries`, add `XWalkView.framework`.

  * For quick test, replace the auto-generated `ViewController.swift` with the corresponding file in `crosswalk-ios/AppShell/AppShell`, which has setup a WKWebView instance for you already.

    Just Remove the auto-generated `ViewController.swift` from your project, and add `crosswalk-ios/AppShell/AppShell/ViewController.swift` into it.

  * Create a directory called `www` in `Echo` to place your HTML5 files and resources.

    And create the `index.html` file in it as your entry page with the contents as follows:

    ```html
    <html>
      <head>
        <meta name='viewport' content='width=device-width' />
        <title>Echo demo of Crosswalk</title>
      </head>
      <body onload='onload()'>
        <h2>Echo Demo of Crosswalk</h2>
        <p id="content" style="font-size: 20px;" />
        <script>
          function onload() {
            xwalk.example.echo.echo('Hello World!', function(msg) {
              document.getElementById('content').innerHTML = msg;
            });
          }
        </script>
      </body>
    </html>
    ```

  * Add the `www` directory into the project.

    In `File` -> `Add Files to "Echo"...`, choose the `www` directory and select `Create folder reference`.

  * We need to crate a `manifest.plist` for `Echo` project to describe the application's configuration.

    * In `File` -> `New...` -> `File...`, choose `iOS` -> `Resource` -> `Property List`, create a plist file with name `manifest.plist` in `Echo` directory. This manifest file will be loaded at the application startup;

    * Add an entry with the key: `start_url` and the Stirng value: `index.html`, which indicates the file name of the entry page, `XWalkView` will locate it in the `www` directory automatically.

    ![manifest1](https://cloud.githubusercontent.com/assets/700736/7226211/36a710c0-e779-11e4-9852-000d3bab8f57.png)

  * Now your `Echo` demo can get run. As we haven't added any extension to support the functionality of the object `xwalk.example.echo`, you can only see the title: `Echo Demo of Crosswalk` on the page.

3. Create The Echo Extension

  * Create a framework target called `EchoExtension` in the `Echo` project.

    In `File` -> `New...` -> `Target...`, choose `Framework & Library` -> `Cocoa Touch Framework`, with name `EchoExtension` and language type `Swift` for convenience.

  * Link `XWalkView` into `EchoExtension` target.

    Select `EchoExtension` target in `Echo` project, in `General` -> `Linked Frameworks and Libraries`, add `XWalkView.framework`.

  * Create the `EchoExtension` extension class.

    Select `EchoExtension` group first, in `File` -> `New...` -> `File...`, choose `iOS` -> `Source` -> `Cocoa Touch Class`, with name `EchoExtension`, subclassing from `XWalkExtension`, and use `Swift` language type.

  * Add the contents into `EchoExtension.swift` as follows:

  ```swift
  import Foundation
  import XWalkView

  class EchoExtension : XWalkExtension {
    func jsfunc_echo(cid: UInt32, message: String, callback: UInt32) -> Bool {
          invokeCallback(callback, key: nil, arguments: ["Echo from native: " + message])
          return true
      }
  }
  ```

  * Then we need to add the extension description section in the `Info.plist` of the `EchoExtension` target, to make the framework users aware that what kind of extensions are provided by this framework, and what are the extension names in both native and JavaScript world.

    * Create `XWalkExtensions` section in the `Info.plist` with `Dictionary` type, then add an entry with `xwalk.example.echo` as key and `EchoExtension` as value.
      ![Info.plist](https://cloud.githubusercontent.com/assets/700736/7226047/58728d94-e777-11e4-9fd4-8d23a24d981f.png)

    This indicates that the extension `EchoExtension` will be exported with the object name: `xwalk.example.echo` in JavaScript.

4. Bundle The Extension With The Application

  * Modify the `manifest.plist` to add the extension configuration to the `Echo` application.

    * Add `xwalk_extensions` section with Array type which describes the extensions that should be loaded within the `Echo` application;

    * And add `xwalk.example.echo` with String type as an entry of `xwalk_extensions`, which indicates that the extension `xwalk.example.echo` should be loaded into the JavaScript context of `Echo` project.
      ![manifest2](https://cloud.githubusercontent.com/assets/700736/7226213/3ef59a9e-e779-11e4-822f-1ef6775723ad.png)

  * Then you can build and run the application to test. If everything goes well, you can see an extra line: `Echo from native: Hello World!` displayed on the screen.

For further information please read the [Getting Started Guide](https://github.com/crosswalk-project/crosswalk-ios/wiki/Getting-Started-With-Crosswalk-for-iOS), and other articles on the [Wiki](https://github.com/crosswalk-project/crosswalk-ios/wiki).

## Community
* Follow the [crosswalk-help](https://lists.crosswalk-project.org/mailman/listinfo/crosswalk-help) mailing list to ask questions
* Follow the [crosswalk-dev](https://lists.crosswalk-project.org/mailman/listinfo/crosswalk-dev) mailing list for development updates
* Find us on IRC: #crosswalk on freenode.net

## Demos
There're 3 built-in demos in the project:

* [Sample](Demos/Sample)

	A simple demo which shows the basic ways of XWalkView embedding, Crosswalk Extension implementation, configuration of extension and application, etc.

* [CordovaPluginDeviceDemo](Demos/Cordova/CordovaPluginDeviceDemo)

	A demo to show the way to integrate Cordova Plugin with the Crosswalk Cordova Extension support, and the usage of `apache.cordova.device` plugin.

* [CordovaPluginFileDemo](Demos/Cordova/CordovaPluginFileDemo)

	Another Cordova Plugin demo, which is imported from https://github.com/Icenium/sample-file.git, which demostrates the usage of `apache.cordova.file` plugin.

NOTICE: Try them after the project's submodules get initialized, using:

  ```bash
  git submodule update --init --recursive
  ```

You may also try out the [HexGL-iOS Demo](https://github.com/jondong/HexGL-iOS) written in HTML5 with the Crosswalk Extension support to evaluate the performance and extensibility of the Crosswalk framework.

## Licence
Crosswalk Project for iOS is available under the BSD license. See the [LICENSE](LICENSE) file for more info.
