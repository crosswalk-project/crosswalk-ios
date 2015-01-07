// Copyright (c) 2014 Intel Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

Extension = function(channel) {
    this.channel = channel;
}

Extension.create = function(channel, namespace, base, isctor) {
    if (!webkit.messageHandlers[channel])
        return null;  // channel has not established

    var obj = window;
    var ns = namespace.split('.');
    var last = ns.pop();
    ns.forEach(function(p){
        if (!obj[p]) obj[p] = {};
        obj = obj[p];
    });
    if (obj[last] instanceof this)
        return null;  // channel is occupied

    if (!isctor) {
        if (base instanceof Object)
            this.aggregate(base, this, [channel]);
        else
            base = new this(channel);
        return obj[last] = base;
    } else if (base instanceof Function) {
        obj[last] = base;
        base.lastInstID = 1;
        base.prototype = new this(channel);
        base.prototype.constructor = base;
        base.destroy = function() {
            for (var i in this) {
                if (!isNaN(Number(i)))
                    this[i].destroy();
            }
            this.prototype.destroy();
        }
        return base.prototype;
    }
}

Extension.defineProperty = function(obj, prop, value, writable) {
    var desc = {
        'configurable': false,
        'enumerable': true,
        'get': function() { return this.properties[prop]; }
    }
    if (writable) {
        desc.set = function(v) {
            this.invokeNative('.' + prop, v);
            this.properties[prop] = v;
        }
    }
    if (!obj.properties)  obj.properties = {};
    obj.properties[prop] = value;
    Object.defineProperty(obj, prop, desc);
}

Extension.aggregate = function(obj, constructor, args) {
    var ctor = constructor;
    if (typeof(ctor) === 'string' || ctor instanceof String)
        ctor = this[ctor];
    if (!(ctor instanceof Function) || !(ctor.prototype instanceof Object))
        return;
    function clone(obj) {
        var copy = {};
        var keys = Object.getOwnPropertyNames(obj);
        for (var i in keys)
            copy[keys[i]] = obj[keys[i]];
        return copy;
    }
    var p = clone(ctor.prototype);
    p.__proto__ = Object.getPrototypeOf(obj);
    obj.__proto__ = p;
    ctor.apply(obj, args);
}

Extension.prototype = {
    invokeNative: function(name, args) {
        if (typeof(name) != 'string' && !(name instanceof String)) {
            console.error('Invalid invocation');
            return;
        }

        var msg = {};
        if (this.instanceID)
            msg.instance = this.instanceID;
        if (name[0] == '.') {
            // Update property
            msg.property = name.substring(1);
            msg.value = args;
            webkit.messageHandlers[this.channel].postMessage(msg);
            return;
        } else if (name == '-') {
            if (!this.instanceID) {
                // Destroy extension
                webkit.messageHandlers[this.channel].postMessage({'destroy': true});
                this.__proto__ = Object.getPrototypeOf(this.__proto__);
            } else {
                // Destroy instance
                var ctor = this.constructor;
                ctor.lastInstID = this.instanceID;
                delete ctor[this.instanceID];
                msg.instance = -this.instanceID;
                webkit.messageHandlers[this.channel].postMessage(msg);
                this.__proto__ = Object.prototype;
            }
            // Cleanup object
            delete this.channel;
            delete this.properties;
            delete this.calls;
            delete this.instanceID;
            delete this.lastCallID;
            return;
        }

        // Only serializable objects can be passed by value.
        var isSerializable = function(obj) {
            if (!(obj instanceof Object))
                return true;
            if (obj instanceof Function)
                return false;
            // TODO: support other types of object (eg. ArrayBuffer)
            // See WebCode::CloneSerializer::dumpIfTerminal() in
            // Source/WebCore/bindings/js/SerializedScriptValue.cpp
            if (obj instanceof Boolean ||
                obj instanceof Date ||
                obj instanceof Number ||
                obj instanceof RegExp ||
                obj instanceof String)
                return true;
            for (var p of Object.getOwnPropertyNames(obj))
                if (!arguments.callee(obj[p]))
                    return false;
            return true;
        }
        var objectRef = function(cid, vid) {
        /*  return {
                'mag': 0x58574C4B ^ 0x4A534F52;
                'id' : (cid << 8) + vid,
            }*/
            return (cid << 8) + vid;
        }

        if (!this.lastCallID) {
            this.lastCallID = 1;
            this.calls = [];
        }
        while (this.calls[this.lastCallID] != undefined)
            ++this.lastCallID;
        var cid = this.lastCallID;

        // Retain objects which had to pass by reference
        var call = [];
        args.forEach(function(val, vid, a) {
            if (!isSerializable(val)) {
                call[vid] = val;
                a[vid] = objectRef(cid, vid);
            }
        })
        if (call.length)
            this.calls[cid] = call;
        else
            cid = 0;

        msg.arguments = args;
        if (name == '+') {
            // Create instance
            var ctor = this.constructor;
            while (ctor[ctor.lastInstID] != undefined)
                ++ctor.lastInstID;
            this.instanceID = ctor.lastInstID;
            this.properties = {};
            for (var i in this.__proto__.properties)
                this.properties[i] = this.__proto__.properties[i];
            ctor[this.instanceID] = this;
            msg.instance = this.instanceID;
        } else {
            // Call method
            msg.method = name;
            msg.callid = cid;
        }
        webkit.messageHandlers[this.channel].postMessage(msg);
    },
    invokeCallback: function(id, key, args) {
        var cid = id >>> 8;
        var vid = id & 0xFF;
        var obj = this.calls[cid][vid];
        if (typeof(key) === 'number' || key instanceof Number)
            obj = obj[key];
        else if (typeof(key) === 'string' || key instanceof String)
            key.split('.').forEach(function(p){ obj = obj[p]; });

        if (obj instanceof Function)
            obj.apply(null, args);
    },
    releaseArguments: function(cid) {
        if (cid) {
            delete this.calls[cid];
            this.lastCallID = cid;
        }
    },
    destroy: function() {
        this.invokeNative('-');
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
            if (!(func instanceof Function))
                func = func.handleEvent;
            func(event);
        }
        return true;
    }
}
