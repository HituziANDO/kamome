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

    var listenerDict = {};
    var webHandlerDict = {};

    var addListener = function (name, listener) {
        if (!(name in listenerDict)) {
            listenerDict[name] = [];
        }

        listenerDict[name].push(listener);

        return this;
    };

    var removeListener = function (name, listener) {
        if (name in listenerDict) {
            for (var i = listenerDict[name].length - 1; i >= 0; --i) {
                if (listenerDict[name][i] === listener) {
                    listenerDict[name].splice(i, 1);
                }
            }
        }

        return this;
    };

    var send = function (name, data) {
        var json = JSON.stringify({ name: name, data: data });

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
            if (name in webHandlerDict) {
                setTimeout(function () {
                    var completion = (function (name) {
                        return function (data) {
                            onReceive(name, data ? JSON.stringify(data) : null);
                        }
                    })(name);
                    webHandlerDict[name](data, completion);
                }, 0);
            }
        }
    };

    var onReceive = function (name, json) {
        if (name in listenerDict) {
            listenerDict[name].forEach(function (listener) {
                listener(json ? JSON.parse(json) : null);
            });
        }
    };

    var addWebHandler = function (name, handler) {
        webHandlerDict[name] = handler;
        return this;
    };

    return {
        addListener: addListener,
        removeListener: removeListener,
        send: send,
        onReceive: onReceive,
        addWebHandler: addWebHandler,
    };
})();
