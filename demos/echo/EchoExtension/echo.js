// Copyright (c) 2014 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

var echoListener = null;

extension.setMessageListener(function(msg) {
    if (echoListener instanceof Function) {
        echoListener(msg);
    }
});

exports.echo = function(msg, callback) {
    echoListener = callback;
    extension.postMessage(msg);
};