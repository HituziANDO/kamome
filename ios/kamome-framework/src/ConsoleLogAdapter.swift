//
// Copyright (c) 2024 Hituzi Ando. All rights reserved.
//
// MIT License
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation
import WebKit

public protocol ConsoleLoggable {
    func consoleLog(_ logMessage: Any)
}

open class DefaultConsoleLogger: ConsoleLoggable {
    public func consoleLog(_ logMessage: Any) {
        print(logMessage)
    }
}

open class ConsoleLogAdapter: NSObject {
    private static let scriptMessageHandlerName = "kamomeLog"

    /// A console logger.
    public var logger: ConsoleLoggable = DefaultConsoleLogger()

    /// Sets this adapter to specified webView.
    ///
    /// - Parameters:
    ///   - webView: A webView.
    public func setTo(_ webView: WKWebView) {
        webView.configuration.userContentController.add(self, name: Self.scriptMessageHandlerName)

        let jsLog = "window.console.log = function(msg) { window.webkit.messageHandlers.\(Self.scriptMessageHandlerName).postMessage(msg); };"
        webView.configuration.userContentController.addUserScript(WKUserScript(source: jsLog,
                                                                               injectionTime: .atDocumentStart,
                                                                               forMainFrameOnly: true))

        let jsWarn = "window.console.warn = function(msg) { window.webkit.messageHandlers.\(Self.scriptMessageHandlerName).postMessage(msg); };"
        webView.configuration.userContentController.addUserScript(WKUserScript(source: jsWarn,
                                                                               injectionTime: .atDocumentStart,
                                                                               forMainFrameOnly: true))

        let jsError = "window.console.error = function(msg) { window.webkit.messageHandlers.\(Self.scriptMessageHandlerName).postMessage(msg); };"
        webView.configuration.userContentController.addUserScript(WKUserScript(source: jsError,
                                                                               injectionTime: .atDocumentStart,
                                                                               forMainFrameOnly: true))
        let jsAssert = """
                       window.console.assert = function(cond, msg) {
                         if (!cond) {
                           window.webkit.messageHandlers.\(Self.scriptMessageHandlerName).postMessage(msg);
                         }
                       };
                       """
        webView.configuration.userContentController.addUserScript(WKUserScript(source: jsAssert,
                                                                               injectionTime: .atDocumentStart,
                                                                               forMainFrameOnly: true))
    }
}

extension ConsoleLogAdapter: WKScriptMessageHandler {
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == Self.scriptMessageHandlerName {
            logger.consoleLog(message.body)
        }
    }
}
