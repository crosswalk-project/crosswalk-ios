// Copyright (c) 2014 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

Extension = function(name, id) {
    this.id = id;
    this.lastCallID = 0;
    this.callbacks = [];

    var a = name.split(".");
    if (a.length > 1) {
        for (var i = 0, n = window; i < a.length; n = n[a[i]], i++)
            if (!n[a[i]]) n[a[i]] = {};
    }
}

Extension.prototype = {
    invokeNative: function(body) {
        if (body == undefined || typeof(body.method) != 'string') {
            console.error('Invalid invocation');
            return;
        }
        window.webkit.messageHandlers[this.id].postMessage(body);
    },
    addCallback: function(callback) {
        while (this.callbacks[this.lastCallID] != undefined) ++this.lastCallID;
        this.callbacks[this.lastCallID] = callback;
        return this.lastCallID;
    },
    removeCallback: function(callID) {
        delete this.callbacks[callID];
        this.lastCallID = callID;
    },
    invokeCallback: function(callID, key, args) {
        var func = this.callbacks[callID];
        if (typeof(func) == 'object')  func = func[key];
        if (typeof(func) == 'function')  func.apply(null, args);
        this.removeCallback(callID);
    }
}
