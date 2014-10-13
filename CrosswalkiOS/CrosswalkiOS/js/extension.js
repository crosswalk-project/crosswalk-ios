// Copyright (c) 2014 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

var messageListener = function() {};

var extension = (function () {
    var postMessage = function(msg) {
        if (msg == undefined) {
            return;
        }
        window.webkit.messageHandlers.xwalk.postMessage(msg);
    }

    var setMessageListener = function(callback) {
        if (callback == undefined) {
            return;
        }
        messageListener = callback;
    }

    return {
        'postMessage' : postMessage,
        'setMessageListener' : setMessageListener,
    }
})()
