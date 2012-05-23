/**
 * Config properties
 * required to be defined before script load
 * // force FlashSocket over native WebSocket
 * __FLASHSOCKET__FORCE_FLASH = false;
 * // enable debug mode for development
 * __FLASHSOCKET__DEBUG = false;
 * // url for flashsocket.swf location
 * __FLASHSOCKET__SWF_LOCATION = 'flashsocket.swf'
 */
(function () {
    'use strict';
    
    // A simple logging function for development
    ;;; function trace() {
    ;;;     if (global[NAMESPACE + 'DEBUG']) {
    ;;;         try {
    ;;;             Function.prototype.apply.call(console.log, console, Array.prototype.slice.call(arguments));
    ;;;         } catch (e) {}
    ;;;         
    ;;;         try {
    ;;;             document.getElementById("console").innerHTML += Array.prototype.join.call(arguments, ' ') + '<br>\n';
    ;;;         } catch (e) {}
    ;;;     }
    ;;; };
    
    var global = window,
        NAMESPACE = '__FLASHSOCKET__',
        FLASH_PLAYER_VERSION = '9.0.0',
        STATE_CONNECTING = 0,
        STATE_OPEN = 1,
        STATE_CLOSING = 2,
        STATE_CLOSED = 3,
        
        // Selected the api to use
        // TODO: allow user to select an api
        api = (global[NAMESPACE + 'FORCE_FLASH'] && FlashSocket) || (global.WebSocket || global.MozWebSocket) || FlashSocket,
        
        instances = [],
        callbacks = [],
        
        // Reference to the flash object
        flash = null,
        // initializeFlash was called
        flashInitialized = false,
        // flash is ready to communicate via ExternalInterface
        flashReady = false,
        // Embed swf into the document
        initializeFlash = function () {
            if (flashInitialized) {
                return;
            }
            
            flashInitialized = true;
            
            swfobject.addDomLoadEvent(function () {
                var loader = document.createElement('div');
                
                loader.id = NAMESPACE + 'LOADER';
                //loader.style.display = 'none';
                document.body.appendChild(loader);
                
                swfobject.embedSWF(
                    // swf url
                    global[NAMESPACE + 'SWF_LOCATION'] || 'flashsocket.swf',
                    // replaced element id
                    loader.id,
                    // swf width
                    '1',
                    // swf height
                    '1',
                    // flash player version
                    FLASH_PLAYER_VERSION,
                    // expressInstall url
                    null,
                    // flashvars
                    null,
                    // params
                    { allowScriptAccess: 'always', wmode: 'transparent' },
                    // attributes
                    { style: 'position:absolute;top:-1px;left:-1px;' },
                    // callback
                    function (e) {
                        ;;; trace('swfobject.embedSWF.callback', e.id, e.success);
                        
                        if (e.success) {
                            flash = e.ref;
                        } else {
                            ;;; trace("Failed to embed swf '" + FlashSocket.SWF_LOCATION + "'");
                        }
                    }
                );
            });
        },
        isFunction = function (obj) {
            return obj instanceof Function;
        },
        // Decorator to run a closure within a delayed event loop
        // This is used to prevent throwing user errors to flash
        // and also allows onexception to throw an uncatchable error
        async = function (closure) {
            return function () {
                var target = this,
                    args = arguments;
                
                setTimeout(function () {
                    closure.apply(target, args);
                }, 1);
            };
        },
        // Call flash methods safely
        // waits for flashReady and handles flash exceptions
        // callback will not be called if an exception is thrown
        callFlash = function (functionName, args, callback) {
            onready(function () {
                try {
                    (callback || isFunction)(flash[functionName].apply(flash, args));
                } catch (e) {
                    throw new Error(flash.getLastException());
                }
            });
        },
        // Supports native WebSocket or has required flash player version
        supported = function () {
            swfobject.hasFlashPlayerVersion(FLASH_PLAYER_VERSION) || !!(global.WebSocket || global.MozWebSocket);
        },
        onready = function (callback) {
            if (flashReady) {
                callback();
            } else {
                initializeFlash();
                callbacks.push(callback);
            }
        };
    
    // FlashSocket Constructor
    function FlashSocket(url, protocols) {
        var instance = this || new FlashSocket(url, protocols);
        
        if (protocols === undefined) {
            protocols = [];
        } else if (Object.prototype.toString.call(protocols) !== '[object Array]') {
            protocols = [protocols];
        }
        
        instance._id = instances.push(instance) - 1;
        instance._events = {
            open: [function (e) { isFunction(instance.onopen) && instance.onopen(e) }],
            error: [function (e) { isFunction(instance.onerror) && instance.onerror(e) }],
            close: [function (e) { isFunction(instance.onclose) && instance.onclose(e) }],
            message: [function (e) { isFunction(instance.onmessage) && instance.onmessage(e) }]
        };
        
        instance.url = url;
        instance.extensions = '';
        instance.protocol = '';
        instance.readyState = STATE_CONNECTING;
        instance.bufferedAmount = 0;
        // Not supported
        instance.binaryType = 'blob';
        instance.onopen = null;
        instance.onerror = null;
        instance.onclose = null;
        instance.onmessage = null;
        
        callFlash("connect", [instance._id, url, protocols]);
        
        return instance;
    }
    
    // FlashSocket Static Public
    FlashSocket.CONNECTING = STATE_CONNECTING;
    FlashSocket.OPEN = STATE_OPEN;
    FlashSocket.CLOSING = STATE_CLOSING;
    FlashSocket.CLOSED = STATE_CLOSED;
    
    // FlashSocket Public methods
    FlashSocket.prototype = {
        close: function (code, reason) {
            ;;; trace("FlashSocket.close", this._id, code, reason);
            callFlash("close", [this._id, code === undefined ? -1 : code, reason === undefined ? "" : reason]);
        },
        send: function (data) {
            ;;; trace("FlashSocket.send", this._id, data);
            // Can't pass undefined to flash so do arugment checks in js
            if (!arguments.length) {
                throw new SyntaxError("Not enough arguments");
            }
            
            var instance = this;
            
            callFlash("send", [instance._id, "" + data], function (bufferedAmount) {
                instance.bufferedAmount = bufferedAmount;
            });
        },
        addEventlistener: function (type, listener) {
            if (!isFunction(listener)) {
                return;
            }
            
            var listeners = this._events[type] = this._events[type] || [];
            
            for (var i = 0, l = listeners.length; i < l; i++) {
                if (listeners[i] === listener) {
                    return;
                }
            }
            
            listeners.push(listener);
        },
        removeEventlistener: function (type, listener) {
            var listeners = this._events[type];
            
            if (listeners) {
                for (var i = 0, l = listeners.length; i < l; i++) {
                    if (listeners[i] === listener) {
                        listeners.splice(i, 1);
                        break;
                    }
                }
            }
        },
        dispatchEvent: function (event) {
            var listeners = this._events[event.type];
            
            if (listeners) {
                for (var i = 0, l = listeners.length; i < l; i++) {
                    listeners[i].call(this, event);
                }
            }
            
            return true;
        }
    };
    
    // Flash to JavaScript interface
    FlashSocket.ExternalInterface = {
        onready: async(function () {
            ;;; trace('FlashSocket.ExternalInterface.onready');
            
            flashReady = true;
            
            // Dispatch FlashSocket.onready event
            for (var i = 0, l = callbacks.length; i < l; i++) {
                callbacks[i]();
            }
            callbacks = null;
        }),
        onopen: async(function (id, url, extensions, protocols) {
            ;;; trace('FlashSocket.ExternalInterface.onopen', id, url, extensions, protocols);
            
            var instance = instances[id];
            
            if (!instance) {
                ;;; trace("Instance not found '" + id + "'");
                return;
            }
            
            // These properties will not change any more
            instance.url = url;
            instance.extensions = extensions;
            instance.protocols = protocols;
            
            instance.dispatchEvent({
                type: 'open',
                target: instance
            });
        }),
        onerror: async(function (id) {
            ;;; trace('FlashSocket.ExternalInterface.onerror', id);
            
            var instance = instances[id];
            
            if (!instance) {
                ;;; trace("Instance not found '" + id + "'");
                return;
            }
            
            instance.dispatchEvent({
                type: 'error',
                target: instance
            });
        }),
        onclose: async(function (id, code, reason, wasClean) {
            ;;; trace('FlashSocket.ExternalInterface.onclose', id, code, reason, wasClean);
            
            var instance = instances[id];
            
            if (!instance) {
                ;;; trace("Instance not found '" + id + "'");
                return;
            }
            
            instance.dispatchEvent({
                type: 'close',
                target: instance,
                code: code,
                reason: reason,
                wasClean: wasClean
            });
        }),
        onmessage: async(function (id, data) {
            ;;; trace('FlashSocket.ExternalInterface.onmessage', id, data);
            
            var instance = instances[id];
            
            if (!instance) {
                ;;; trace("Instance not found '" + id + "'");
                return;
            }
            
            instance.dispatchEvent({
                type: 'message',
                target: instance,
                data: data
            });
        }),
        onexception: async(function (id, name, message) {
            ;;; trace('FlashSocket.ExternalInterface.onexception', id, name, message);
            
            //throw new (global[name] || Error)(message);
            throw new Error(message);
        }),
        onreadystatechange: function (id, state) {
            ;;; trace('FlashSocket.ExternalInterface.onreadystatechange', id, state);
            
            var instance = instances[id];
            
            if (!instance) {
                ;;; trace("Instance not found '" + id + "'");
                return;
            }
            
            instance.readyState = state;
        },
        onbufferempty: function (id, name, message) {
            ;;; trace('FlashSocket.ExternalInterface.bufferempty', id);
            
            var instance = instances[id];
            
            if (!instance) {
                ;;; trace("Instance not found '" + id + "'");
                return;
            }
            
            instance.bufferedAmount = 0;
        }
    };
    
    // Support
    api.supported = supported;
    //api.onready = onready;
    
    // Export
    global.FlashSocket = api;
}());