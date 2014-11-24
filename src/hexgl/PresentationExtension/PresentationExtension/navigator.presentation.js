/**
 * Copyright (c) 2013 Intel Corporation. All rights reserved.
 * Use of this source code is governed by a BSD-style license that can be
 * found in the LICENSE file.
 */

exports.aggregate(Extension.EventTarget);

exports.defineProperty("displayAvailable", {'value': true, 'writeable': false});

var _nextRequestId = 0;
var _showRequests = {};

function DOMError(msg) {
    this.name = msg;
}

function ShowRequest(id, successCallback, errorCallback) {
    this._requestId = id;
    this._successCallback = successCallback;
    this._errorCallback = errorCallback;
}

function RemoteWindow(viewId) {
    var _viewId = viewId;
    return {
        "postMessage": function(message, scope) {
            exports.invokeNative("postMessage", [{"viewId": _viewId}, {"message": message}, {"scope": scope}]);
        },
        "close": function() {
            exports.invokeNative("close", [{"viewId": this._viewId}]);
        }
    }
}

/* TODO(hmin): Add Promise support instead of callback approach. */
exports.requestShow = function(url, successCallback, errorCallback) {
    if (typeof url !== "string" || typeof successCallback !== "function") {
        console.error("Invalid parameter for presentation.requestShow!");
        return;
    }

    // errorCallback is optional.
    if (errorCallback && typeof errorCallback != "function") {
        console.error("Invalid parameter for presentation.requestShow!");
        return;
    }

    var requestId = ++_nextRequestId;
    var request = new ShowRequest(requestId, successCallback, errorCallback);
    _showRequests[requestId] = request;
    // Requested url should be absolute.
    // If the requested url is relative, we need to combine it with baseUrl to make it absolute.
    var baseUrl = location.href.substring(0, location.href.lastIndexOf("/")+1);

    this.invokeNative("requestShow", [{"requestId": requestId}, {"url": url}, {"baseUrl": baseUrl}])
}

function handleShowSucceeded(requestId, viewId) {
    var request = _showRequests[requestId];
    if (request) {
        var view = new RemoteWindow(viewId);
        request._successCallback.apply(null, [view]);
        delete _showRequests[requestId];
    }
}

function handleShowFailed(requestId, errorMessage) {
    var request = _showRequests[requestId];
    if (request) {
        var error = new DOMError(errorMessage);
        if (request._errorCallback)
            request._errorCallback.apply(null, [error]);
        delete _showRequests[requestId];
    }
}

exports.addEventListener("ShowSucceeded", function(event) {
                         setTimeout(function() {
                                    handleShowSucceeded(event.requestId, event.data);
                                    }, 0);
                         });
exports.addEventListener("ShowFailed", function(event) {
                         setTimeout(function() {
                                    handleShowFailed(event.requestId, event.data);
                                    }, 0);
                         });
