//
// Copyright (c) 2021 Hituzi Ando. All rights reserved.
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

/// The data type transferred from the JavaScript to the native.
public typealias TransferData = [String: Any?]

public enum KamomeError: Error {
    case invalidJSONObject
    case commandNotAdded(String)
}

class Messenger {

    private static let jsObj = "window.KM"

    static func completeMessage(with webView: WKWebView, data: Any?, for requestID: String) throws {
        if let data = data {
            if !JSONSerialization.isValidJSONObject(data) {
                throw KamomeError.invalidJSONObject
            }

            let params = String(data: try JSONSerialization.data(withJSONObject: data), encoding: .utf8)!
            run(javaScript: "\(jsObj).onComplete('\(params)', '\(requestID)')", with: webView)
        }
        else {
            run(javaScript: "\(jsObj).onComplete(null, '\(requestID)')", with: webView)
        }
    }

    static func failMessage(with webView: WKWebView, error: String?, for requestID: String) {
        if let error = error {
            run(javaScript: "\(jsObj).onError('\(error)', '\(requestID)')", with: webView)
        }
        else {
            run(javaScript: "\(jsObj).onError(null, '\(requestID)')", with: webView)
        }
    }

    // TODO: kamome.jsがロード完了していないときの処理
    static func sendMessage(with webView: WKWebView, data: Any?, callbackID: String?, for name: String) throws {
        if let data = data {
            if !JSONSerialization.isValidJSONObject(data) {
                throw KamomeError.invalidJSONObject
            }

            let params = String(data: try JSONSerialization.data(withJSONObject: data), encoding: .utf8)!

            if let callbackID = callbackID {
                run(javaScript: "\(jsObj).onReceive('\(name)', '\(params)', '\(callbackID)')", with: webView)
            }
            else {
                run(javaScript: "\(jsObj).onReceive('\(name)', '\(params)', null)", with: webView)
            }
        }
        else {
            if let callbackID = callbackID {
                run(javaScript: "\(jsObj).onReceive('\(name)', null, '\(callbackID)')", with: webView)
            }
            else {
                run(javaScript: "\(jsObj).onReceive('\(name)', null, null)", with: webView)
            }
        }
    }
}

private extension Messenger {

    static func run(javaScript: String, with webView: WKWebView) {
        DispatchQueue.main.async {
            webView.evaluateJavaScript(javaScript) { value, error in
                if let error = error {
                    print("[Kamome] ERROR: \(error)")
                }
            }
        }
    }
}

public protocol Completable {
    /// Tells whether already resolved or rejected.
    var isCompleted: Bool { get }
    /// Sends resolved result to a JavaScript callback function.
    func resolve()
    /// Sends resolved result with a dictionary data to a JavaScript callback function.
    func resolve(_ data: [String: Any?])
    /// Sends resolved result with an array data to a JavaScript callback function.
    func resolve(_ data: [Any?])
    /// Sends rejected result to a JavaScript callback function.
    func reject()
    /// Sends rejected result with an error message to a JavaScript callback function.
    func reject(_ errorMessage: String?)
}

open class Completion: Completable {

    private let requestID: String

    private weak var webView: WKWebView!
    private var completed = false

    public init(webView: WKWebView, requestID: String) {
        self.webView = webView
        self.requestID = requestID
    }

    public var isCompleted: Bool {
        completed
    }

    public func resolve() {
        if completed {
            return
        }

        completed = true

        try? Messenger.completeMessage(with: webView, data: nil, for: requestID)
    }

    public func resolve(_ data: [String: Any?]) {
        if completed {
            return
        }

        completed = true

        try? Messenger.completeMessage(with: webView, data: data, for: requestID)
    }

    public func resolve(_ data: [Any?]) {
        if completed {
            return
        }

        completed = true

        try? Messenger.completeMessage(with: webView, data: data, for: requestID)
    }

    public func reject() {
        reject(nil)
    }

    public func reject(_ errorMessage: String?) {
        if completed {
            return
        }

        completed = true

        Messenger.failMessage(with: webView, error: errorMessage, for: requestID)
    }
}

open class LocalCompletion: Completable {

    public typealias Callback = (_ result: Any?, _ errorMessage: String?) -> Void

    private var callback: Callback?
    private var completed = false

    public init(callback: Callback? = nil) {
        self.callback = callback
    }

    deinit {
        callback = nil
    }

    public var isCompleted: Bool {
        completed
    }

    public func resolve() {
        if completed {
            return
        }

        completed = true

        if let callback = callback {
            callback(nil, nil)
        }
    }

    public func resolve(_ data: [String: Any?]) {
        if completed {
            return
        }

        completed = true

        if let callback = callback {
            callback(data, nil)
        }
    }

    public func resolve(_ data: [Any?]) {
        if completed {
            return
        }

        completed = true

        if let callback = callback {
            callback(data, nil)
        }
    }

    public func reject() {
        reject(nil)
    }

    public func reject(_ errorMessage: String?) {
        if completed {
            return
        }

        completed = true

        if let callback = callback {
            callback(nil, errorMessage ?? "Rejected")
        }
    }
}

open class Command {

    public typealias Handler = (_ name: String, _ data: TransferData?, _ completion: Completable) -> Void

    /// A command name.
    let name: String

    private let handler: Handler

    /// Creates a command object.
    ///
    /// - Parameters:
    ///   - name: A command name.
    ///   - handler: A function that processes the command.
    public init(_ name: String, handler: @escaping Handler) {
        self.name = name
        self.handler = handler
    }

    func execute(data: TransferData?, completion: Completable) {
        handler(name, data, completion)
    }
}

public enum HowToHandleNonExistentCommand {
    /// Anyway resolved passing null.
    case resolved
    /// Always rejected and passing an error message.
    case rejected
    /// Always raises an exception.
    case exception
}

/// Receives a result from the JavaScript receiver when it processed a task of a command.
/// An error occurs when the native client receives it from the JavaScript receiver, otherwise it will be null.
public typealias SendMessageCallback = (_ commandName: String, _ result: Any?, _ errorMessage: String?) -> Void

open class Client: NSObject {

    public static let scriptMessageHandlerName = "kamomeSend"

    /// How to handle non-existent command.
    public var howToHandleNonExistentCommand: HowToHandleNonExistentCommand = .resolved

    private weak var webView: WKWebView!
    private var commands: [String: Command] = [:]

    /// - Parameters:
    ///   - webView: A webView for this framework.
    public init(_ webView: WKWebView) {
        super.init()
        self.webView = webView
        self.webView.configuration.userContentController.add(self, name: Self.scriptMessageHandlerName)
    }

    /// Adds a command called by the JavaScript code.
    ///
    /// - Parameters:
    ///   - command: A command object.
    @discardableResult
    public func add(_ command: Command) -> Client {
        commands[command.name] = command
        return self
    }

    /// Removes a command of specified name.
    ///
    /// - Parameters:
    ///   - commandName: A command name that you will remove.
    public func remove(_ commandName: String) {
        if hasCommand(commandName) {
            commands.removeValue(forKey: commandName)
        }
    }

    /// Tells whether specified command is added.
    public func hasCommand(_ name: String) -> Bool {
        commands.contains { $0.key == name }
    }

    /// Sends a message to the JavaScript receiver.
    ///
    /// - Parameters:
    ///   - commandName A command name.
    ///   - callback: A callback.
    public func send(_ commandName: String, callback: SendMessageCallback? = nil) {
        if let callback = callback {
            let callbackID = add(sendMessageCallback: callback)
            try? Messenger.sendMessage(with: webView, data: nil, callbackID: callbackID, for: commandName)
        }
        else {
            try? Messenger.sendMessage(with: webView, data: nil, callbackID: nil, for: commandName)
        }
    }

    /// Sends a message with a data as Dictionary to the JavaScript receiver.
    ///
    /// - Parameters:
    ///   - data: A data as Dictionary.
    ///   - commandName: A command name.
    ///   - callback: A callback.
    public func send(_ data: [String: Any?], commandName: String, callback: SendMessageCallback? = nil) {
        if let callback = callback {
            let callbackID = add(sendMessageCallback: callback)
            try? Messenger.sendMessage(with: webView, data: data, callbackID: callbackID, for: commandName)
        }
        else {
            try? Messenger.sendMessage(with: webView, data: data, callbackID: nil, for: commandName)
        }
    }

    /// Sends a message with a data as Array to the JavaScript receiver.
    ///
    /// - Parameters:
    ///   - data: A data as Array.
    ///   - commandName: A command name.
    ///   - callback: A callback.
    public func send(_ data: [Any?], commandName: String, callback: SendMessageCallback? = nil) {
        if let callback = callback {
            let callbackID = add(sendMessageCallback: callback)
            try? Messenger.sendMessage(with: webView, data: data, callbackID: callbackID, for: commandName)
        }
        else {
            try? Messenger.sendMessage(with: webView, data: data, callbackID: nil, for: commandName)
        }
    }

    /// Executes a command added to this client.
    ///
    /// - Parameters:
    ///   - commandName: A command name.
    ///   - callback: A callback.
    public func execute(_ commandName: String, callback: LocalCompletion.Callback?) {
        execute(commandName, data: nil, callback: callback)
    }

    /// Executes a command added to this client with a data.
    ///
    /// - Parameters:
    ///   - commandName: A command name.
    ///   - data: A data as Dictionary.
    ///   - callback: A callback.
    public func execute(_ commandName: String, data: TransferData?, callback: LocalCompletion.Callback?) {
        try! handle(commandName, data: data, completion: LocalCompletion(callback: callback))
    }
}

extension Client: WKScriptMessageHandler {

    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == Self.scriptMessageHandlerName else { return }
        guard let body = message.body as? String,
              let data = body.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }

        let params = obj["data"] as? TransferData
        let completion = Completion(webView: webView, requestID: obj["id"] as! String)
        try! handle(obj["name"] as! String, data: params, completion: completion)
    }
}

private extension Client {

    func handle(_ commandName: String, data: TransferData?, completion: Completable) throws {
        if hasCommand(commandName) {
            let command = commands[commandName]
            command?.execute(data: data, completion: completion)
        }
        else {
            switch howToHandleNonExistentCommand {
                case .rejected:
                    completion.reject("CommandNotAdded")
                case .exception:
                    throw KamomeError.commandNotAdded("\(commandName) command not added.")
                default:
                    completion.resolve()
            }
        }
    }

    func add(sendMessageCallback: @escaping SendMessageCallback) -> String {
        let callbackID = UUID().uuidString

        // Add a temporary command receiving a result from the JavaScript handler.
        add(Command(callbackID) { name, data, completion in
            if let data = data {
                if let success = data["success"] as? Bool, success {
                    sendMessageCallback(name, data["result"]!, nil)
                }
                else {
                    let reason: String
                    if let error = data["error"] as? String {
                        reason = error
                    }
                    else {
                        reason = "UnknownError"
                    }
                    sendMessageCallback(name, nil, reason)
                }
            }
            else {
                sendMessageCallback(name, nil, "UnknownError")
            }

            completion.resolve()

            // Remove the temporary command.
            self.remove(callbackID)
        })

        return callbackID
    }
}

/// MARK: - Console Log

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
    }
}

extension ConsoleLogAdapter: WKScriptMessageHandler {

    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == Self.scriptMessageHandlerName {
            logger.consoleLog(message.body)
        }
    }
}
