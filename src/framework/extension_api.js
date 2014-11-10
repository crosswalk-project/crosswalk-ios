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
    invokeNative: function(name, args) {
        if (typeof(name) != 'string') {
            console.error('Invalid invocation');
            return;
        }
        var body = name[0] == '.' ?
                { 'property': name.substring(1), 'value': args } :
                { 'method': name, 'arguments': args };
        webkit.messageHandlers[this.id].postMessage(body);
    },
    addCallback: function(callback) {
        while (this.callbacks[this.lastCallID] != undefined)
            ++this.lastCallID;
        this.callbacks[this.lastCallID] = callback;
        return this.lastCallID;
    },
    removeCallback: function(callID) {
        delete this.callbacks[callID];
        this.lastCallID = callID;
    },
    invokeCallback: function(callID, key, args) {
        var func = this.callbacks[callID];
        if (typeof(func) == 'object')
            func = func[key];
        if (typeof(func) == 'function')
            func.apply(null, args);
        this.removeCallback(callID);
    },
    defineProperty: function(prop, desc) {
        var name = "." + prop;
        var d = { 'configurable': false, 'enumerable': true }
        if (desc.hasOwnProperty("value")) {
            // a data descriptor
            this.invokeNative(name, desc.value);
            if (desc.writable == false) {
                // read only property
                d.value = desc.value;
                d.writable = false;
            } else {
                // read/write property
                var store = "_" + prop;
                Object.defineProperty(this, store, {
                                      'configurable': false,
                                      'enumerable': false,
                                      'value': desc.value,
                                      'writable': true
                                      });
                d.get = function() { return this[store]; }
                d.set = function(v) { this.invokeNative(name, v); this[store] = v; }
            }
        } else if (typeof(desc.get) === 'function'){
            // accessor descriptor
            this.invokeNative(name, desc.get());
            d.get = desc.get
            if (typeof(desc.set) === 'function') {
                d.set = function(v) { desc.set(v); this.invokeNative(name, desc.get()); }
            }
        }
        Object.defineProperty(this, prop, d);
    },
    aggregate: function(constructor, args) {
        var ctor = constructor;
        if (typeof(ctor) === 'string')
            ctor = Extension[ctor];
        if (typeof(ctor) != 'function' || typeof(ctor.prototype) != 'object')
            return;
        function clone(obj) {
            var copy = {};
            var keys = Object.getOwnPropertyNames(obj);
            for (var i in keys)
                copy[keys[i]] = obj[keys[i]];
            return copy;
        }
        var p = clone(ctor.prototype);
        p.__proto__ = Object.getPrototypeOf(this);
        this.__proto__ = p;
        ctor.apply(this, args);
    }
}

// A simple implementation of EventTarget interface
Extension.EventTarget = function() {
    this.listeners = {}
}

Extension.EventTarget.prototype = {
    addEventListener: function(type, listener, capture) {
        if (!listener)  return;

        var list = this.listeners[type];
        if (!list) {
            list = new Array();
            this.listeners[type] = list;
        } else if (list.indexOf(listener) >= 0) {
            return;
        }
        list.push(listener);
    },
    removeEventListener: function(type, listener, capture) {
        var list = this.listeners[type];
        if (!list || !listener)
            return;
        var i = list.indexOf(listener);
        if (i >= 0)
            list.splice(i, 1);
    },
    dispatchEvent: function(event) {
        var list = this.listeners[event.type];
        if (!list)  return;
        for (var i = 0; i < list.length; ++i) {
            var func = list[i];
            if (typeof(func) != 'function')
                func = func.handleEvent;
            func(event);
        }
        return true;
    }
}
