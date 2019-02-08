/**
 * kamome.js Rev.7
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

    /**
     * Tells whether the OS is Android.
     *
     * @return {boolean} Returns true if the OS is Android
     */
    var isAndroid = function () {
        return (navigator.userAgent.toLowerCase().indexOf('android') > 0);
    };

    /**
     * Tells whether the OS is iOS.
     *
     * @return {boolean} Returns true if the OS is iOS
     */
    var isIOS = function () {
        var ua = navigator.userAgent.toLowerCase();
        return (ua.indexOf('iphone') > 0 || ua.indexOf('ipad') > 0 || ua.indexOf('ipod') > 0);
    };

    var Error = {
        requestTimeout: 'RequestTimeout',
        rejected:       'Rejected',
        canceled:       'Canceled',
    };

    var receiverDict = {};
    var webHandlerDict = {};
    var requests = [];
    var isRequesting = false;
    var requestTimer = null;
    var requestTimeout = 10000; // Default value is 10 seconds

    /**
     * Sets a timeout for a request. If given `time` <= 0, the request timeout is disabled.
     *
     * @param {number} time A time in millisecond
     * @return {*}
     */
    var setDefaultRequestTimeout = function (time) {
        requestTimeout = time;
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
        receiverDict[name] = receiver;
        return this;
    };

    /**
     * Removes a receiver for given command if it is registered.
     *
     * @param {string} name A command name
     * @return {*}
     */
    var removeReceiver = function (name) {
        if (name in receiverDict) {
            delete receiverDict[name];
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
            timeout = requestTimeout;
        }

        if (callback) {
            requests.push({ name: name, data: data, timeout: timeout, callback: callback });
            _send();
            return null;
        }
        else {
            return new Promise(function (resolve, reject) {
                requests.push({ name: name, data: data, timeout: timeout, resolve: resolve, reject: reject });
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
        if (requests.length === 0) {
            return;
        }

        _clearTimer();

        isRequesting = false;

        var msg = reason ? ':' + reason : '';
        var req = requests.shift();

        if ('callback' in req) {
            req.callback(null, Error.canceled + ':' + req.name + msg);
        }
        else if ('reject' in req) {
            req.reject(Error.canceled + ':' + req.name + msg);
        }

        if (requests.length > 0) {
            _send();
        }
    };

    /**
     * @private
     */
    var _send = function () {
        if (isRequesting) {
            return;
        }

        isRequesting = true;

        var req = requests[0];
        var json = JSON.stringify({ name: req.name, data: req.data });

        if (isIOS() && 'webkit' in window) {  // Require WKWebView
            setTimeout(function () {
                window.webkit.messageHandlers.kamomeSend.postMessage(json);
            }, 0);
        }
        else if (isAndroid() && 'kamomeAndroid' in window) {
            setTimeout(function () {
                window.kamomeAndroid.kamomeSend(json);
            }, 0);
        }
        else {
            if (req.name in webHandlerDict) {
                setTimeout(function () {
                    var resolve = (function (name) {
                        return function (data) {
                            onComplete(name, data ? JSON.stringify(data) : null);
                        }
                    })(req.name);

                    var reject = (function (name) {
                        return function (errorMessage) {
                            onError(name, errorMessage);
                        }
                    })(req.name);

                    webHandlerDict[req.name](req.data, resolve, reject);
                }, 0);
            }
        }

        if (req.timeout > 0) {
            _clearTimer();

            requestTimer = setTimeout(function () {
                _clearTimer();

                isRequesting = false;

                var req = requests.shift();

                if ('callback' in req) {
                    req.callback(null, Error.requestTimeout + ':' + req.name);
                }
                else if ('reject' in req) {
                    req.reject(Error.requestTimeout + ':' + req.name);
                }

                if (requests.length > 0) {
                    _send();
                }
            }, req.timeout);
        }
    };

    /**
     * @private
     */
    var _clearTimer = function () {
        if (requestTimer !== null) {
            clearTimeout(requestTimer);
            requestTimer = null;
        }
    };

    var onComplete = function (name, json, nullObj) {
        _clearTimer();

        isRequesting = false;

        var data = json ? JSON.parse(json) : null;
        var req = requests.shift();

        if (name === req.name) {
            if ('callback' in req) {
                req.callback(data, null);
            }
            else if ('resolve' in req) {
                req.resolve(data);
            }
        }

        if (requests.length > 0) {
            _send();
        }

        return null;
    };

    var onError = function (name, errorMessage) {
        _clearTimer();

        isRequesting = false;

        var msg = errorMessage ? ':' + errorMessage : '';
        var req = requests.shift();

        if (name === req.name) {
            if ('callback' in req) {
                req.callback(null, Error.rejected + ':' + req.name + msg);
            }
            else if ('reject' in req) {
                req.reject(Error.rejected + ':' + req.name + msg);
            }
        }

        if (requests.length > 0) {
            _send();
        }

        return null;
    };

    var onReceive = function (name, json, callbackId) {
        if (name in receiverDict) {
            var result = receiverDict[name](json ? JSON.parse(json) : null);

            if (isAndroid()) {
                return { callbackId: callbackId, result: result };
            }
            else {
                return JSON.stringify({ callbackId: callbackId, result: result });
            }
        }

        if (isAndroid()) {
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
        webHandlerDict[name] = handler;
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
