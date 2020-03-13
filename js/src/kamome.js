/**
 * kamome.js v3.13
 * https://github.com/HituziANDO/kamome
 *
 * MIT License
 *
 * Copyright (c) 2020 Hituzi Ando
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
window.Kamome = (function (Undefined) {

    var Error = {
        requestTimeout: 'RequestTimeout',
        rejected:       'Rejected',
        canceled:       'Canceled',
    };

    var android = (function () {
        /**
         * Tells whether your app has the Kamome Android client.
         *
         * @return {boolean}
         */
        var hasClient = function () {
            return (navigator.userAgent.toLowerCase().indexOf('android') > 0) && 'kamomeAndroid' in window;
        };

        var _send = function (json) {
            setTimeout(function () {
                window.kamomeAndroid.kamomeSend(json);
            }, 0);
        };

        return {
            hasClient: hasClient,
            _send:     _send,
        };
    })();

    var iOS = (function () {
        /**
         * Tells whether your app has the Kamome iOS client.
         *
         * @return {boolean}
         */
        var hasClient = function () {
            // Require WKWebView
            return 'webkit' in window;
        };

        var _send = function (json) {
            setTimeout(function () {
                window.webkit.messageHandlers.kamomeSend.postMessage(json);
            }, 0);
        };

        return {
            hasClient: hasClient,
            _send:     _send,
        };
    })();

    var browser = (function () {
        var _handlerDict = {};

        /**
         * Adds a command when it will be processed in the browser not the WebView.
         * The handler format is following.
         *
         *  ```
         *  function (data, resolve, reject) {
         *      // Something to do
         *      // Then, if succeeded
         *      // resolve(response);   // response is any object or null
         *      // Else
         *      // reject('Error Message');
         *  }
         *  ```
         *
         * @param name {string} A command name.
         * @param handler {Function} A handler.
         * @return {*}
         */
        var addCommand = function (name, handler) {
            _handlerDict[name] = handler;
            return this;
        };

        /**
         * Tells whether specified command is registered.
         *
         * @param name {string} A command name.
         * @return {boolean}
         */
        var _hasCommand = function (name) {
            return (name in _handlerDict);
        };

        /**
         * Executes a command with specified request.
         *
         * @param req {{id:string, name:string, data:Object}} A request object.
         */
        var _execCommand = function (req) {
            setTimeout(function () {
                var resolve = (function (name, id) {
                    return function (data) {
                        onComplete(data ? JSON.stringify(data) : null, id);
                    }
                })(req.name, req.id);

                var reject = (function (id) {
                    return function (errorMessage) {
                        onError(errorMessage, id);
                    }
                })(req.id);

                _handlerDict[req.name](req.data, resolve, reject);
            }, 0);
        };

        return {
            addCommand:   addCommand,
            _hasCommand:  _hasCommand,
            _execCommand: _execCommand,
        };
    })();

    var hook = (function () {
        var _beforeActions = {};
        var _afterActions = {};

        var before = function (commandName, handler) {
            _beforeActions[commandName] = handler;
            return this;
        };

        var after = function (commandName, handler) {
            _afterActions[commandName] = handler;
            return this;
        };

        var _execActionBefore = function (commandName) {
            if (_beforeActions[commandName]) {
                _beforeActions[commandName]();
            }
        };

        var _execActionAfter = function (commandName) {
            if (_afterActions[commandName]) {
                _afterActions[commandName]();
            }
        };

        return {
            before:            before,
            after:             after,
            _execActionBefore: _execActionBefore,
            _execActionAfter:  _execActionAfter,
        };
    })();

    var _receiverDict = {};
    var _requests = [];
    var _isRequesting = false;
    var _requestTimeout = 10000;    // Default value is 10 seconds

    /**
     * `Kamome.send` method expects a 'resolve'/'reject' response will be returned in a duration.
     * If the request is timed out, it's callback calls `reject` with requestTimeout error.
     * You can change default request timeout.
     * Sets a timeout for a request. If given `time` <= 0, the request timeout function is disabled.
     *
     * @param {number} time A time in millisecond
     * @return {*}
     */
    var setDefaultRequestTimeout = function (time) {
        _requestTimeout = time;
        return this;
    };

    /**
     * Registers a receiver for given command. The receiver function receives a JSON message from the native.
     *
     * @param {string} name A command name
     * @param {Function} receiver A receiver is following.
     *
     *  ```
     *  function(json, resolve, reject) {
     *      // Something to do
     *      // Then, if succeeded
     *      // resolve(response);   // response is any object or null
     *      // Else
     *      // reject('Error Message');
     *  }
     *  ```
     *
     * @return {*}
     */
    var addReceiver = function (name, receiver) {
        _receiverDict[name] = receiver;
        return this;
    };

    /**
     * Removes a receiver for given command if it is registered.
     *
     * @param {string} name A command name
     * @return {*}
     */
    var removeReceiver = function (name) {
        if (name in _receiverDict) {
            delete _receiverDict[name];
        }

        return this;
    };

    /**
     * Sends a JSON message to the native.
     *
     * @param {string} name A command name
     * @param {Object} data
     * @param {Function|null} callback A callback is
     *  ```
     *  function(data, error) {
     *      // If the request is resolved, an `error` is null, otherwise the request is rejected
     *  }
     *  ```
     * @param {number|null} timeout An individual timeout for this request
     * @return {Promise|null} Returns a promise if a `callback` is null, otherwise returns null
     */
    var send = function (name, data, callback, timeout) {
        hook._execActionBefore(name);

        if (timeout === null || timeout === Undefined) {
            timeout = _requestTimeout;
        }

        if (callback) {
            _requests.push({
                id:       _uuid(),
                name:     name,
                data:     data,
                timeout:  timeout,
                callback: callback
            });
            _send();
            return null;
        }
        else {
            return new Promise(function (resolve, reject) {
                _requests.push({
                    id:      _uuid(),
                    name:    name,
                    data:    data,
                    timeout: timeout,
                    resolve: resolve,
                    reject:  reject
                });
                _send();
            });
        }
    };

    /**
     * Cancels current request immediately if requesting to native. Then the request calls reject handler.
     *
     * @param {string|null} reason A reason why a request is cancel
     */
    var cancelCurrentRequest = function (reason) {
        if (_requests.length === 0) {
            return;
        }

        _isRequesting = false;

        var msg = reason ? ':' + reason : '';

        _shiftRequest(function (req) {
            if ('callback' in req) {
                req.callback(null, Error.canceled + ':' + req.name + msg);
            }
            else if ('reject' in req) {
                req.reject(Error.canceled + ':' + req.name + msg);
            }
        });
    };

    /**
     * @private
     */
    var _send = function () {
        if (_requests.length === 0 || _isRequesting) {
            return;
        }

        _isRequesting = true;

        var req = _requests[0];
        var json = JSON.stringify({ name: req.name, data: req.data, id: req.id });

        if (iOS.hasClient()) {
            iOS._send(json);
        }
        else if (android.hasClient()) {
            android._send(json);
        }
        else if (browser._hasCommand(req.name)) {
            browser._execCommand(req);
        }

        if (req.timeout > 0) {
            setTimeout((function (id) {
                return function () {
                    _isRequesting = false;

                    if (_requests.length > 0 && _requests[0].id === id) {
                        _shiftRequest(function (timedOutReq) {
                            if ('callback' in timedOutReq) {
                                timedOutReq.callback(null, Error.requestTimeout + ':' + timedOutReq.name);
                            }
                            else if ('reject' in timedOutReq) {
                                timedOutReq.reject(Error.requestTimeout + ':' + timedOutReq.name);
                            }
                        });
                    }
                };
            })(req.id), req.timeout);
        }
    };

    /**
     * @private
     */
    var _shiftRequest = function (didShift) {
        didShift(_requests.shift());
        _send();
    };

    /**
     * Tells whether an argument is Object.
     *
     * @param {*} obj
     * @return {boolean} true if an argument is Object
     * @private
     */
    var _isObj = function (obj) {
        return ({}).toString.call(obj) === '[object Object]';
    };

    /**
     * Tells whether an argument is Function.
     *
     * @param {*} obj
     * @return {boolean} true if an argument is Function
     * @private
     */
    var _isFun = function (obj) {
        return ({}).toString.call(obj) === '[object Function]';
    };

    /**
     * @return {string} Returns a UUID string
     * @private
     */
    var _uuid = function () {
        return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function (c) {
            var r = Math.random() * 16 | 0;
            var v = c === 'x' ? r : (r & 0x3 | 0x8);
            return v.toString(16);
        }).toLowerCase();
    };

    /**
     * @private
     */
    var _merge = function (obj1, obj2) {
        obj2 = obj2 || {};

        for (var key in obj2) {
            if (obj2[key] === null || obj2[key] === Undefined) {
                obj1[key] = null;
            }
            else if (_isObj(obj2[key])) {
                obj1[key] = _merge(obj1[key] || {}, obj2[key]);
            }
            else {
                obj1[key] = obj2[key];
            }
        }

        return obj1;
    };

    /**
     * Called from the native client when sent message is processed successfully.
     */
    var onComplete = function (json, requestId) {
        _isRequesting = false;

        if (_requests.length > 0 && _requests[0].id === requestId) {
            var data = json ? JSON.parse(json) : null;

            _shiftRequest(function (req) {
                if ('callback' in req) {
                    req.callback(data, null);
                }
                else if ('resolve' in req) {
                    req.resolve(data);
                }

                hook._execActionAfter(req.name);
            });
        }

        return null;
    };

    /**
     * Called from the native client when sent message is processed incorrectly.
     */
    var onError = function (errorMessage, requestId) {
        _isRequesting = false;

        if (_requests.length > 0 && _requests[0].id === requestId) {
            var msg = errorMessage ? ':' + errorMessage : '';

            _shiftRequest(function (req) {
                if ('callback' in req) {
                    req.callback(null, Error.rejected + ':' + req.name + msg);
                }
                else if ('reject' in req) {
                    req.reject(Error.rejected + ':' + req.name + msg);
                }

                hook._execActionAfter(req.name);
            });
        }

        return null;
    };

    /**
     * Receives a message from the native client.
     */
    var onReceive = function (name, json, callbackId) {
        if (name in _receiverDict) {
            new Promise(function (resolve, reject) {
                var handle = _receiverDict[name];
                var result = handle(json ? JSON.parse(json) : null, resolve, reject);

                if (result) {
                    // Resolve synchronously.
                    resolve(result);
                }
            }).then(function (result) {
                send(callbackId, { result: result, success: true });
            }).catch(function (error) {
                // Send an error message as string type.
                send(callbackId, { error: error, success: false });
            });
        }

        return null;
    };

    var _module = {
        Error:                    Error,
        android:                  android,
        iOS:                      iOS,
        browser:                  browser,
        hook:                     hook,
        setDefaultRequestTimeout: setDefaultRequestTimeout,
        addReceiver:              addReceiver,
        removeReceiver:           removeReceiver,
        send:                     send,
        cancelCurrentRequest:     cancelCurrentRequest,
        onComplete:               onComplete,
        onError:                  onError,
        onReceive:                onReceive,
    };

    _module.extension = {
        /**
         * Adds a command method with default value to Kamome object.
         *
         * @param {string} commandName A command name
         * @param {Object|null} defaultValue Default value of the command
         * @param {string|null} methodName A method name of the command if it is given
         * @return {*}
         * @deprecated
         */
        addCommand: function (commandName, defaultValue, methodName) {
            _module[methodName || commandName] = (function (name, defaultValue) {
                return function (dataOrFunc, callback, timeout) {
                    var value = _isFun(dataOrFunc) ? dataOrFunc(_merge({}, defaultValue)) : _merge(_merge({}, defaultValue), dataOrFunc);
                    return send(name, value, callback, timeout);
                }
            })(commandName, defaultValue);

            return this;
        }
    };

    return _module;
})();
// export const Kamome = window.Kamome;
