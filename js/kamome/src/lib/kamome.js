/**
 * kamome.js v4.0.2
 * https://github.com/HituziANDO/kamome
 *
 * MIT License
 *
 * Copyright (c) 2021 Hituzi Ando
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
window.KM = (function () {

    const Error = {
        requestTimeout: 'RequestTimeout',
        rejected: 'Rejected',
        canceled: 'Canceled',
    };

    const android = (function () {
        /**
         * Tells whether your app has the Kamome Android client.
         *
         * @return {boolean}
         */
        const hasClient = () => (navigator.userAgent.toLowerCase().indexOf('android') > 0) && 'kamomeAndroid' in window;

        const _send = json => setTimeout(() => window.kamomeAndroid.kamomeSend(json), 0);

        return {
            hasClient: hasClient,
            _send: _send,
        };
    })();

    const iOS = (function () {
        /**
         * Tells whether your app has the Kamome iOS client.
         * (Requires WKWebView.)
         *
         * @return {boolean}
         */
        const hasClient = () => 'webkit' in window && !!window.webkit.messageHandlers.kamomeSend;

        const _send = json => setTimeout(() => window.webkit.messageHandlers.kamomeSend.postMessage(json), 0);

        return {
            hasClient: hasClient,
            _send: _send,
        };
    })();

    const browser = (function () {
        const _handlerDict = {};

        /**
         * Adds a command when it will be processed in the browser not the WebView.
         * The handler format is following.
         *
         *  ```
         *  function (data, resolve, reject) {
         *      // Something to do.
         *      // If succeeded
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
        const addCommand = function (name, handler) {
            _handlerDict[name] = handler;
            return this;
        };

        /**
         * Tells whether specified command is registered.
         *
         * @param name {string} A command name.
         * @return {boolean}
         */
        const _hasCommand = name => (name in _handlerDict);

        /**
         * Executes a command with specified request.
         *
         * @param req {{id:string, name:string, data:Object}} A request object.
         */
        const _execCommand = req => setTimeout(() => {
            const resolve = data => onComplete(data ? JSON.stringify(data) : null, req.id);
            const reject = errorMessage => onError(errorMessage, req.id);
            _handlerDict[req.name](req.data, resolve, reject);
        }, 0);

        return {
            addCommand: addCommand,
            _hasCommand: _hasCommand,
            _execCommand: _execCommand,
        };
    })();

    const _receivers = {};
    const _requests = {};
    let _requestTimeout = 10000;    // Default value is 10 seconds

    /**
     * `KM.send` method expects a 'resolve'/'reject' response will be returned in a duration.
     * If the request is timed out, it's callback calls `reject` with requestTimeout error.
     * You can change default request timeout.
     * Sets a timeout for a request. If given `time` <= 0, the request timeout function is disabled.
     *
     * @param {number} time A time in millisecond
     * @return {*}
     */
    const setDefaultRequestTimeout = function (time) {
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
     *      // Something to do.
     *      // If succeeded
     *      // resolve(response);   // response is any object or null
     *      // Else
     *      // reject('Error Message');
     *  }
     *  ```
     *
     * @return {*}
     */
    const addReceiver = function (name, receiver) {
        _receivers[name] = receiver;
        return this;
    };

    /**
     * Removes a receiver for given command if it is registered.
     *
     * @param {string} name A command name
     * @return {*}
     */
    const removeReceiver = function (name) {
        if (name in _receivers) {
            delete _receivers[name];
        }

        return this;
    };

    /**
     * Sends a JSON message to the native.
     *
     * @param {string} name A command name.
     * @param {Object} data
     * @param {number|null} timeout Timeout for this request. If this argument is omitted or null, default timeout is used.
     * @return {Promise}
     */
    const send = (name, data, timeout) => {
        timeout = timeout || _requestTimeout;

        return new Promise((resolve, reject) => {
            const id = _uuid();
            const req = {
                id: id,
                name: name,
                data: data,
                timeout: timeout,
                resolve: resolve,
                reject: reject
            };
            _requests[id] = req;

            const json = JSON.stringify({ name: req.name, data: req.data, id: req.id });

            if (iOS.hasClient()) {
                iOS._send(json);
            } else if (android.hasClient()) {
                android._send(json);
            } else if (browser._hasCommand(req.name)) {
                browser._execCommand(req);
            }

            if (req.timeout > 0) {
                setTimeout(() => {
                    const timedOutReq = _requests[req.id];

                    if (timedOutReq) {
                        timedOutReq.reject(Error.requestTimeout + ':' + timedOutReq.name);
                        delete _requests[timedOutReq.id];
                    }
                }, req.timeout);
            }
        });
    };

    /**
     * @return {string} Returns a UUID string
     * @private
     */
    const _uuid = () => 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, c => {
        const r = Math.random() * 16 | 0;
        const v = c === 'x' ? r : (r & 0x3 | 0x8);
        return v.toString(16);
    }).toLowerCase();

    /**
     * Called from the native client when sent message is processed successfully.
     */
    const onComplete = (json, requestId) => {
        const req = _requests[requestId];

        if (req) {
            const data = json ? JSON.parse(json) : null;
            req.resolve(data);
            delete _requests[requestId];
        }

        return null;
    };

    /**
     * Called from the native client when sent message is processed incorrectly.
     */
    const onError = (errorMessage, requestId) => {
        const req = _requests[requestId];

        if (req) {
            const msg = errorMessage ? ':' + errorMessage : '';
            req.reject(Error.rejected + ':' + req.name + msg);
            delete _requests[requestId];
        }

        return null;
    };

    /**
     * Receives a message from the native client.
     */
    const onReceive = (name, json, callbackId) => {
        if (name in _receivers) {
            new Promise((resolve, reject) => {
                const handle = _receivers[name];
                handle(json ? JSON.parse(json) : null, resolve, reject);
            })
                .then(result => send(callbackId, { result: result, success: true }))
                // Send an error message as string type.
                .catch(error => send(callbackId, { error: error, success: false }));
        }

        return null;
    };

    return {
        Error: Error,
        android: android,
        iOS: iOS,
        browser: browser,
        setDefaultRequestTimeout: setDefaultRequestTimeout,
        addReceiver: addReceiver,
        removeReceiver: removeReceiver,
        send: send,
        onComplete: onComplete,
        onError: onError,
        onReceive: onReceive,
    };
})();
// For supporting v3 native client.
window.Kamome = window.KM;
export const Kamome = window.Kamome;
export const KM = window.KM;
