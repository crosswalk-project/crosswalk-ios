// Copyright (c) 2014 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

exports.echo = function(msg, callback) {
    var callID = extension.addCallback(callback);
    extension.invokeNative({
        'method': "echo",
        'arguments': [
            {'message': msg},
            {'callback': callID}
        ]
    });
};