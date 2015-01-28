# Crosswalk for iOS

## Introduction
Crosswalk for iOS is a sub-project of [Crosswalk](https://crosswalk-project.org/), it aims to provide a web runtime to develop sophisticated iOS native or hybrid applications.

* Extended WKWebView

  Crosswalk for iOS build on top of `WKWebView`, the mordern WebKit framework debuted in iOS 8.0. We extend the WKWebView to build Crosswalk extension framework within, and we are intended to bring the least intrusion to the interface to make developers use it as natural as WKWebView itself. For the detailed information you may refer to [Embedding Mode & WKWebView](https://github.com/otcshare/crosswalk-ios/wiki/Embedding-Mode-&-Native-APIs).

* Crosswalk Extension Framework

  Extension is a way to extend the ability of Crosswalk runtime. You can write your functionalities in both Swift and Objective-C codes and expose it as a JavaScript function or object. All JavaScript stub codes can be generated automatically under the hood based on the native interface. For more information please refer to [Crosswalk Extension](https://github.com/otcshare/crosswalk-ios/wiki/Extensions).

* Cordova Plugins Support

  To leverage existing Cordova plugins, a Cordova extension is provided to simulate Cordova environment. You only need to place source files of Cordova plugins into your project and register the classes of plugins in the manifest. For more information please refer to [Cordova Plugins Support](https://github.com/otcshare/crosswalk-ios/wiki/Cordova-Plugin-Support).

## System Requirement
Development:
* iOS SDK 8+
* Xcode 6+

Deployment:
* iOS 8+

## Quickstart
Here we'd like to show you the quick demo to setup a native application with Crosswalk extension support.

1. Clone the repository

2. Create an application project
  * Create an iOS application project called `Echo`.
    * In File -> "Save As Workspace..." to create a workspace for the project.
    * Add `XWalkView` project into your workspace, and link the `XWalkView.framework` into your app target.
    * For quick test, replace `ViewController.swift`, `AppDelegate.swift` and `Main.storyboard` with the corresponding files in crosswalk-ios/AppShell/AppShell, which have setup a WKWebView instance for you.
    * Create a directory called `www` to place your HTML5 files and resources, and create `index.html` in it as your entry page:
  ```html
  <html>
    <head>
      <meta name='viewport' content='width=device-width'>
      <title>Echo demo of Crosswalk<title/>
    </head>
    <body>
      <h2>Echo demo of Crosswalk<h2/>
      <p id="content" style="font-size: 20px;"/>
      <script>
        xwalk.sample.echo.echo('Hello World!', function(msg) {
          document.getElementById('content').innerHTML = msg;
        });
      </script>
    </body>
  </html>
  ```

3. Create the extension
  * Create a target called `EchoExtension` inside the `Echo` project.
  * Create the echo extension class called `EchoExtension` which derive from `XWalkExtension`, and add it into the target.
  ```swift
  class EchoExtension : XWalkExtension {
    func jsfunc_echo(cid: UInt32, message: String, callback: UInt32) -> Bool {
          invokeCallback(callback, key: nil, arguments: ["Echo from native: " + message])
          return true
      }
  }
  ```
  * Create `XWalkExtensions` section in the project's `Info.plist` in Dictionary type, then add an entry with `xwalk.example.echo` as key and `EchoExtension` as value in String type.

4. Bundle the extension with the application
  * In `Build Phase` of `Echo` project settings, add `XWalkView.framework` into the `Embed Frameworks`, to embed those frameworks into the  app bundle.
    * Create a `manifest.plist` and add into `Echo` project,
      * add `start_url` section in String type with value `index.html`;
      * add `xwalk_extensions` section in Array type, and add `xwalk.example.echo` as a entry in String type.
    * Then you can build and run the application to test.

For further information please read the [Getting Started Guide](https://github.com/otcshare/crosswalk-ios/wiki/Getting-Started-With-Crosswalk-for-iOS), and other articles on the [Wiki](https://github.com/otcshare/crosswalk-ios/wiki).

## Community
* Follow the [crosswalk-help](https://lists.crosswalk-project.org/mailman/listinfo/crosswalk-help) mailing list to ask questions
* Follow the [crosswalk-dev](https://lists.crosswalk-project.org/mailman/listinfo/crosswalk-dev) mailing list for development updates
* Find us on IRC: #crosswalk on freenode.net

## Licence
Crosswalk for iOS is available under the BSD license. See the [LICENSE](https://github.com/otcshare/crosswalk-ios/blob/master/LICENSE) file for more info.
