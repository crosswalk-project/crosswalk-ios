var echoListener = null;

extension.setMessageListener(function(msg) {
    if (echoListener instanceof Function) {
        echoListener(msg);
    }
});

var echo = function(msg, callback) {
    echoListener = callback;
    extension.postMessage(msg);
};