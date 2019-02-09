/**
 * kamome.js Rev.8
 * https://github.com/HituziANDO/kamome
 *
 * MIT License
 *
 * Copyright (c) 2019 Hituzi Ando
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

    var _receiverDict = {};
    var _webHandlerDict = {};
    var _requests = [];
    var _isRequesting = false;
    var _requestTimeout = 10000;    // Default value is 10 seconds

    /**
     * Sets a timeout for a request. If given `time` <= 0, the request timeout is disabled.
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
     * @param {Function} receiver A receiver is
     *  ```
     *  function(json) {
     *      ...
     *      return result;  // Any object or null
     *  }
     *  ```
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
     * @param {Function} callback (Optional) A callback is
     *  ```
     *  function(data, error) {
     *      // If the request is resolved, an `error` is null, otherwise the request is rejected
     *  }
     *  ```
     * @param {number} timeout (Optional) An individual timeout for this request
     * @return {Promise|null} Returns a promise if a `callback` is null, otherwise returns null
     */
    var send = function (name, data, callback, timeout) {
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
     * @param {string|null} reason (Optional) A reason why a request is cancel
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

        if (_isIOS() && 'webkit' in window) {  // Require WKWebView
            setTimeout(function () {
                window.webkit.messageHandlers.kamomeSend.postMessage(json);
            }, 0);
        }
        else if (_isAndroid() && 'kamomeAndroid' in window) {
            setTimeout(function () {
                window.kamomeAndroid.kamomeSend(json);
            }, 0);
        }
        else {
            if (req.name in _webHandlerDict) {
                setTimeout(function () {
                    var resolve = (function (name, id) {
                        return function (data) {
                            onComplete(name, data ? JSON.stringify(data) : null, id);
                        }
                    })(req.name, req.id);

                    var reject = (function (name, id) {
                        return function (errorMessage) {
                            onError(name, errorMessage, id);
                        }
                    })(req.name, req.id);

                    _webHandlerDict[req.name](req.data, resolve, reject);
                }, 0);
            }
        }

        if (req.timeout > 0) {
            setTimeout((function (id) {
                return function () {
                    _isRequesting = false;

                    if (_requests.length > 0 && _requests[0].id === id) {
                        _shiftRequest(function (req) {
                            if ('callback' in req) {
                                req.callback(null, Error.requestTimeout + ':' + req.name);
                            }
                            else if ('reject' in req) {
                                req.reject(Error.requestTimeout + ':' + req.name);
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
     * Tells whether the OS is Android.
     *
     * @return {boolean} Returns true if the OS is Android
     * @private
     */
    var _isAndroid = function () {
        return (navigator.userAgent.toLowerCase().indexOf('android') > 0);
    };

    /**
     * Tells whether the OS is iOS.
     *
     * @return {boolean} Returns true if the OS is iOS
     * @private
     */
    var _isIOS = function () {
        var ua = navigator.userAgent.toLowerCase();
        return (ua.indexOf('iphone') > 0 || ua.indexOf('ipad') > 0 || ua.indexOf('ipod') > 0);
    };

    /**
     * @return {string} Returns a UUID string
     * @private
     */
    var _uuid = function () {
        return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function (c) {
            const r = Math.random() * 16 | 0;
            const v = c === 'x' ? r : (r & 0x3 | 0x8);
            return v.toString(16);
        }).toLowerCase();
    };

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
            });
        }

        return null;
    };

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
            });
        }

        return null;
    };

    var onReceive = function (name, json, callbackId) {
        if (name in _receiverDict) {
            var result = _receiverDict[name](json ? JSON.parse(json) : null);

            if (_isAndroid()) {
                return { callbackId: callbackId, result: result };
            }
            else {
                return JSON.stringify({ callbackId: callbackId, result: result });
            }
        }

        if (_isAndroid()) {
            return { callbackId: callbackId, result: null };
        }
        else {
            return JSON.stringify({ callbackId: callbackId, result: null });
        }
    };

    /**
     *
     * @param {string} name A command name
     * @param {Function} handler A handler is
     * ```
     *  function (data, resolve, reject) {
     *      // Something to do
     *      // Then, if succeeded
     *      // resolve(response);   // response is any object or null
     *      // Else
     *      // reject('Error Message');
     *  }
     * ```
     * @return {*}
     */
    var addWebHandler = function (name, handler) {
        _webHandlerDict[name] = handler;
        return this;
    };

    return {
        Error:                    Error,
        setDefaultRequestTimeout: setDefaultRequestTimeout,
        addReceiver:              addReceiver,
        removeReceiver:           removeReceiver,
        send:                     send,
        cancelCurrentRequest:     cancelCurrentRequest,
        onComplete:               onComplete,
        onError:                  onError,
        onReceive:                onReceive,
        addWebHandler:            addWebHandler,
    };
})();
// export default Kamome = window.Kamome;
