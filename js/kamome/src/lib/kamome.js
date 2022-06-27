/**
 * kamome.js v5.2.0
 * https://github.com/HituziANDO/kamome
 *
 * MIT License
 *
 * Copyright (c) 2022 Hituzi Ando
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
    /**
     * The version code of the Kamome JavaScript library.
     */
    const VERSION_CODE = 50200

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

        /**
         * @param {string} json
         * @private
         */
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

        /**
         * @param {string} json
         * @private
         */
        const _send = json => setTimeout(() => window.webkit.messageHandlers.kamomeSend.postMessage(json), 0);

        return {
            hasClient: hasClient,
            _send: _send,
        };
    })();

    const flutter = (function () {
        /**
         * Tells whether your app has the Kamome Flutter client.
         * Supports [webview_flutter](https://pub.dev/packages/webview_flutter) plugin and
         * [flutter_inappwebview](https://pub.dev/packages/flutter_inappwebview) plugin.
         *
         * @return {boolean}
         */
        const hasClient = () => 'kamomeFlutter' in window || 'flutter_inappwebview' in window;

        /**
         * @param {string} json
         * @private
         */
        const _send = json => {
            if ('kamomeFlutter' in window) {
                setTimeout(() => window.kamomeFlutter.postMessage(json), 0);
            } else if ('flutter_inappwebview' in window) {
                setTimeout(() => window.flutter_inappwebview.callHandler('kamomeFlutter', json), 0);
            }
        };

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
         * Removes a command of specified name.
         *
         * @param name A command name that you will remove.
         * @return {*}
         */
        const removeCommand = function (name) {
            if (hasCommand(name)) {
                delete _handlerDict[name];
            }
            return this;
        };

        /**
         * Tells whether specified command is registered.
         *
         * @param name {string} A command name.
         * @return {boolean}
         */
        const hasCommand = name => (name in _handlerDict);

        /**
         * Sends a message to the receiver added by KM.addReceiver method.
         *
         * @param name {string} A command name.
         * @param data {any} A JSON data.
         * @return {Promise<any>}
         */
        const send = (name, data) => {
            return new Promise((resolve, reject) => {
                const callbackId = "_km_" + name + "_" + _uuid();

                // Add a temporary command.
                addCommand(callbackId, (result, cmdResolve) => {
                    if (result) {
                        if (result["success"]) {
                            resolve(result["result"]);
                        } else {
                            const reason = result["error"] || "UnknownError";
                            reject(reason);
                        }
                    } else {
                        reject("UnknownError");
                    }

                    cmdResolve();

                    // Remove the temporary command.
                    removeCommand(callbackId);
                });

                // Sends a message to the receiver added by KM.addReceiver method.
                onReceive(name, data, callbackId);
            })
        }

        /**
         * Executes a command with specified request.
         *
         * @param req {{id:string, name:string, data:Object}} A request object.
         */
        const _execCommand = req => setTimeout(() => {
            const resolve = data => onComplete(data, req.id);
            const reject = errorMessage => onError(errorMessage ? encodeURIComponent(errorMessage) : null, req.id);
            _handlerDict[req.name](req.data, resolve, reject);
        }, 0);

        // Add preset commands.
        addCommand('_kamomeSYN', (_, resolve) => resolve({ versionCode: VERSION_CODE }));
        addCommand('_kamomeACK', (_, resolve) => resolve());

        return {
            addCommand: addCommand,
            removeCommand: removeCommand,
            hasCommand: hasCommand,
            send: send,
            _execCommand: _execCommand,
        };
    })();

    const _COMMAND_SYN = '_kamomeSYN';
    const _COMMAND_ACK = '_kamomeACK';

    const _receivers = {};
    const _requests = {};
    let _requestTimeout = 10000;    // Default value is 10 seconds
    let _isReady = false;
    /**
     * Tells whether the native client is ready.
     */
    const isReady = () => _isReady;
    /**
     * @type {Function|null}
     * @private
     */
    let _onReady = null;
    /**
     * Sets a ready event listener.
     * The listener is called when Kamome iOS, Android, or Flutter client goes ready state.
     *
     * @param {Function|null} listener
     */
    const setReadyEventListener = function (listener) {
        _onReady = listener;
        return this;
    };

    /**
     * `KM.send` method expects a 'resolve'/'reject' response will be returned in a duration.
     * If the request is timed out, it's callback calls `reject` with requestTimeout error.
     * You can change default request timeout.
     * Sets a timeout for a request. If given `time` <= 0, the request timeout function is disabled.
     *
     * @param {number} time A time in millisecond
     */
    const setDefaultRequestTimeout = function (time) {
        _requestTimeout = time;
        return this;
    };

    /**
     * If this method returns true, KM has no native clients such as an iOS client.
     *
     * @return {boolean} true if KM has no native clients, otherwise false.
     */
    const hasNoClients = () => !iOS.hasClient() && !android.hasClient() && !flutter.hasClient();

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
     */
    const addReceiver = function (name, receiver) {
        _receivers[name] = receiver;
        return this;
    };

    /**
     * Removes a receiver for given command if it is registered.
     *
     * @param {string} name A command name
     */
    const removeReceiver = function (name) {
        if (name in _receivers) {
            delete _receivers[name];
        }

        return this;
    };

    const _sendRequest = (req) => {
        const json = JSON.stringify({ name: req.name, data: req.data, id: req.id });

        if (iOS.hasClient()) {
            iOS._send(json);
        } else if (android.hasClient()) {
            android._send(json);
        } else if (flutter.hasClient()) {
            flutter._send(json);
        } else if (browser.hasCommand(req.name)) {
            browser._execCommand(req);
        }

        if (req.timeout > 0) {
            // Set the request timeout.
            setTimeout(() => {
                const timedOutReq = _requests[req.id];

                if (timedOutReq) {
                    timedOutReq.reject(Error.requestTimeout + ':' + timedOutReq.name);
                    delete _requests[timedOutReq.id];
                }
            }, req.timeout);
        }
    };

    let _retryCount = 0;
    const _waitForReadyAndSendRequests = () => {
        if (!_isReady) {
            if (_retryCount < 50) {
                _retryCount++;
                setTimeout(_waitForReadyAndSendRequests, 200);
            } else {
                console.error('[kamome.js] Waiting for ready has timed out.')
            }
            return;
        }

        for (const id in _requests) {
            const req = _requests[id];
            _sendRequest(req);
        }
    };

    /**
     * Sends a JSON message to the native.
     *
     * @param {string} name A command name.
     * @param {Object} data
     * @param {number|null} timeout Timeout in milliseconds for this request. If this argument is omitted or null, default timeout is used.
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

            if (name === _COMMAND_SYN || name === _COMMAND_ACK) {
                // Send initialization commands to ready.
                _sendRequest(req);
            } else {
                _waitForReadyAndSendRequests();
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
     *
     * @param {any|null} json
     * @param {string} requestId
     * @return {null}
     */
    const onComplete = (json, requestId) => {
        const req = _requests[requestId];

        if (req) {
            req.resolve(json);
            delete _requests[requestId];
        }

        return null;
    };

    /**
     * Called from the native client when sent message is processed incorrectly.
     *
     * @param {string|null} errorMessage
     * @param {string} requestId
     * @return {null}
     */
    const onError = (errorMessage, requestId) => {
        const req = _requests[requestId];

        if (req) {
            const msg = errorMessage ? ':' + decodeURIComponent(errorMessage) : '';
            req.reject(Error.rejected + ':' + req.name + msg);
            delete _requests[requestId];
        }

        return null;
    };

    /**
     * Receives a message from the native client.
     *
     * @param {string} name
     * @param {any|null} json
     * @param {string} callbackId
     * @return {null}
     */
    const onReceive = (name, json, callbackId) => {
        if (name in _receivers) {
            new Promise((resolve, reject) => {
                const handle = _receivers[name];
                handle(json, resolve, reject);
            })
                .then(result => send(callbackId, { result: result || null, success: true }, null))
                // Send an error message as string type.
                .catch(error => send(callbackId, { error: error || null, success: false }, null));
        }

        return null;
    };

    const _ready = () => {
        send(_COMMAND_SYN, null, 5000)
            .then(data => {
                if (VERSION_CODE !== data.versionCode) {
                    console.warn('[kamome.js] The Kamome native library version does not match. Please update it to latest version.');
                }

                _isReady = true;

                setTimeout(() => {
                    if (_onReady) {
                        _onReady();
                    }
                }, 0);

                send(_COMMAND_ACK, null, 5000)
                    .catch(() => console.warn('[kamome.js] Failed to send ACK.'));
            })
            .catch(() => {
                console.warn('[kamome.js] Failed to send SYN. Please update the Kamome native library to latest version.');
                // Set true for backward compatibility. (< 5.1.0)
                _isReady = true;
            });
    };

    // Add the ready event listener.
    if ('flutter_inappwebview' in window) {
        window.addEventListener('flutterInAppWebViewPlatformReady', _ready);
    } else {
        window.addEventListener('DOMContentLoaded', _ready);
    }

    return {
        VERSION_CODE: VERSION_CODE,
        Error: Error,
        android: android,
        iOS: iOS,
        flutter: flutter,
        browser: browser,
        setDefaultRequestTimeout: setDefaultRequestTimeout,
        hasNoClients: hasNoClients,
        addReceiver: addReceiver,
        removeReceiver: removeReceiver,
        send: send,
        onComplete: onComplete,
        onError: onError,
        onReceive: onReceive,
        isReady: isReady,
        setReadyEventListener: setReadyEventListener,
    };
})();
export const KM = window.KM;
