# Crosswalk Project for iOS

[![Build Status](https://travis-ci.org/crosswalk-project/crosswalk-ios.svg?branch=master)](https://travis-ci.org/crosswalk-project/crosswalk-ios)

## Introduction

Crosswalk Project for iOS is a sub-project of [Crosswalk](https://crosswalk-project.org/), it aims to provide a web runtime to develop sophisticated iOS native or hybrid applications.

* Extended WKWebView

  Crosswalk Project for iOS is built on top of `WKWebView`, the mordern WebKit framework debuted in iOS 8. We extend the WKWebView to build Crosswalk extension framework within. For the detailed information you may refer to [Embedding Mode & WKWebView](https://github.com/crosswalk-project/crosswalk-ios/wiki/Embedding-Mode-&-Native-APIs).

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

## Quick Start

You can refer to the [Getting Started Guide](https://github.com/crosswalk-project/crosswalk-ios/wiki/Getting-Started-With-Crosswalk-for-iOS), following the quick start demo to create a Crosswalk hybrid application with a simple extension support. You can also refter to other articles on the project [Wiki](https://github.com/crosswalk-project/crosswalk-ios/wiki).

## Community

* Follow the [crosswalk-help](https://lists.crosswalk-project.org/mailman/listinfo/crosswalk-help) mailing list to ask questions

* Follow the [crosswalk-dev](https://lists.crosswalk-project.org/mailman/listinfo/crosswalk-dev) mailing list for development updates

* Find us on IRC: #crosswalk on freenode.net

## Demos
There is a built-in demo in the project:

* [Sample](Demos/Sample)

	A simple demo which shows the basic ways of XWalkView embedding, Crosswalk Extension implementation, configuration of extension and application, etc.

And there are two Cordova extension demos in [iOS Extension Crosswalk](https://github.com/crosswalk-project/ios-extensions-crosswalk) project:

* [CordovaPluginDeviceDemo](https://github.com/crosswalk-project/ios-extensions-crosswalk/tree/master/demos/CordovaPluginDeviceDemo)

	A demo to show the way to integrate Cordova Plugin with the Crosswalk Cordova Extension support, and the usage of `apache.cordova.device` plugin.

* [CordovaPluginFileDemo](https://github.com/crosswalk-project/ios-extensions-crosswalk/tree/master/demos/CordovaPluginFileDemo)

	Another Cordova Plugin demo, which is imported from https://github.com/Icenium/sample-file.git, which demostrates the usage of `apache.cordova.file` plugin.

Follow the Quick Start instruction of [iOS Extension Crosswalk](https://github.com/crosswalk-project/ios-extensions-crosswalk) project to build and run the demos.

## Licence
Crosswalk Project for iOS is available under the BSD license. See the [LICENSE](LICENSE) file for more info.
