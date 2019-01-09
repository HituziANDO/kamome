/**
 * kamome.js Rev.2
 * https://github.com/HituziANDO/kamome
 *
 * MIT License
 *
 * Copyright (c) 2018 Hituzi Ando
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
window.Kamome = (function () {

    /**
     *
     * @return {boolean} Returns true if the OS is Android
     */
    var isAndroid = function () {
        return (navigator.userAgent.toLowerCase().indexOf('android') > 0);
    };

    /**
     *
     * @return {boolean} Returns true if the OS is iOS
     */
    var isIOS = function () {
        var ua = navigator.userAgent.toLowerCase();
        return (ua.indexOf('iphone') > 0 || ua.indexOf('ipad') > 0 || ua.indexOf('ipod') > 0);
    };

    var receiverDict = {};
    var webHandlerDict = {};
    var requests = [];
    var isRequesting = false;

    /**
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

    var removeReceiver = function (name) {
        if (name in receiverDict) {
            delete receiverDict[name];
        }

        return this;
    };

    /**
     *
     * @param {string} name A command name
     * @param {Object} data
     * @param {Function} callback (Optional) A callback
     * @return {Promise|null}
     */
    var send = function (name, data, callback) {
        if (callback) {
            requests.push({ name: name, data: data, callback: callback });
            _send();
            return null;
        }
        else {
            return new Promise(function (resolve) {
                requests.push({ name: name, data: data, resolve: resolve });
                _send();
            });
        }
    };

    var _send = function () {
        if (isRequesting) {
            return;
        }

        isRequesting = true;

        var req = requests[0];
        var json = JSON.stringify({ name: req.name, data: req.data });

        if (isIOS()) {
            if ('webkit' in window) {
                setTimeout(function () {
                    window.webkit.messageHandlers.kamomeSend.postMessage(json);
                }, 0);
            }
            else {
                // TODO: impl
            }
        }
        else if (isAndroid()) {
            if ('kamomeAndroid' in window) {
                setTimeout(function () {
                    window.kamomeAndroid.kamomeSend(json);
                }, 0);
            }
            else {
                // TODO: impl
            }
        }
        else {
            if (req.name in webHandlerDict) {
                setTimeout(function () {
                    var completion = (function (name) {
                        return function (data) {
                            onComplete(name, data ? JSON.stringify(data) : null);
                        }
                    })(req.name);
                    webHandlerDict[req.name](req.data, completion);
                }, 0);
            }
        }
    };

    var onComplete = function (name, json, nullObj) {
        isRequesting = false;

        var data = json ? JSON.parse(json) : null;
        var req = requests.shift();

        if (name === req.name) {
            if ('callback' in req) {
                req.callback(data);
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
     * @param {Function} handler
     * @return {*}
     */
    var addWebHandler = function (name, handler) {
        webHandlerDict[name] = handler;
        return this;
    };

    return {
        addReceiver:    addReceiver,
        removeReceiver: removeReceiver,
        send:           send,
        onComplete:     onComplete,
        onReceive:      onReceive,
        addWebHandler:  addWebHandler,
    };
})();
