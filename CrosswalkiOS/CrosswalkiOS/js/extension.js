var messageListener = function() {};

var extension = (function () {
    var postMessage = function(msg) {
        if (msg == undefined) {
            return;
        }
        window.webkit.messageHandlers.xwalk-extension.postMessage(msg);
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
