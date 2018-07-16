/**
 *
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
     * @param {Function} callback (Optional)
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

    var onComplete = function (name, json) {
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
    };

    var onReceive = function (name, json) {
        if (name in receiverDict) {
            receiverDict[name](json ? JSON.parse(json) : null);
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
        addReceiver: addReceiver,
        removeReceiver: removeReceiver,
        send: send,
        onComplete: onComplete,
        onReceive: onReceive,
        addWebHandler: addWebHandler,
    };
})();
