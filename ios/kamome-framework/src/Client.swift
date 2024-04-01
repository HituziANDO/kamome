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

/// The version code of the Kamome framework.
public let kamomeVersionCode = 50303

/// Receives a result from the JavaScript receiver when it processed a task of a command.
/// An error occurs when the native client receives it from the JavaScript receiver, otherwise it will be null.
public typealias SendMessageCallback = (_ commandName: String, _ result: Any?, _ errorMessage: String?) -> Void

open class Client: NSObject {

    public static let scriptMessageHandlerName = "kamomeSend"
    private static let commandSYN = "_kamomeSYN"
    private static let commandACK = "_kamomeACK"

    /// How to handle non-existent command.
    public var howToHandleNonExistentCommand: HowToHandleNonExistentCommand = .resolved
    /// A ready event handler.
    /// The handler is called when the Kamome JavaScript library goes ready state.
    public var readyEventHandler: (() -> Void)?
    /// Tells whether the Kamome JavaScript library is ready.
    public private(set) var isReady = false

    fileprivate weak var webView: WKWebView?
    private var commands: [String: Command] = [:]
    private var requests = [Request]()
    private let waitForReady = WaitForReady()

    /// - Parameters:
    ///   - webView: A webView for this framework.
    public init(_ webView: WKWebView) {
        super.init()
        self.webView = webView
        self.webView!.configuration.userContentController.add(self, name: Self.scriptMessageHandlerName)

        // Add preset commands.
        self.add(Command(Self.commandSYN) { [weak self] _, _, completion in
                self?.isReady = true
                completion.resolve(["versionCode": kamomeVersionCode])
            })
            .add(Command(Self.commandACK) { [weak self] _, _, completion in
                DispatchQueue.main.async {
                    self?.readyEventHandler?()
                }
                completion.resolve()
            })
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
        let callbackID = addSendMessageCallback(callback, commandName: commandName)
        requests.append(Request(name: commandName, callbackID: callbackID, data: nil))

        waitForReadyAndSendRequests()
    }

    /// Sends a message with a data as Dictionary to the JavaScript receiver.
    ///
    /// - Parameters:
    ///   - data: A data as Dictionary.
    ///   - commandName: A command name.
    ///   - callback: A callback.
    public func send(_ data: [String: Any?], commandName: String, callback: SendMessageCallback? = nil) {
        let callbackID = addSendMessageCallback(callback, commandName: commandName)
        requests.append(Request(name: commandName, callbackID: callbackID, data: data))

        waitForReadyAndSendRequests()
    }

    /// Sends a message with a data as Array to the JavaScript receiver.
    ///
    /// - Parameters:
    ///   - data: A data as Array.
    ///   - commandName: A command name.
    ///   - callback: A callback.
    public func send(_ data: [Any?], commandName: String, callback: SendMessageCallback? = nil) {
        let callbackID = addSendMessageCallback(callback, commandName: commandName)
        requests.append(Request(name: commandName, callbackID: callbackID, data: data))

        waitForReadyAndSendRequests()
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
        guard let webView else { return }
        guard message.name == Self.scriptMessageHandlerName else { return }
        guard let body = message.body as? String,
              let data = body.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return }

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

    func addSendMessageCallback(_ callback: SendMessageCallback?, commandName: String) -> String {
        let callbackID = "_km_\(commandName)_\(UUID().uuidString)"

        // Add a temporary command receiving a result from the JavaScript handler.
        add(Command(callbackID) { name, data, completion in
            if let data {
                if let success = data["success"] as? Bool, success {
                    callback?(name, data["result"]!, nil)
                }
                else {
                    let reason: String
                    if let error = data["error"] as? String {
                        reason = error
                    }
                    else {
                        reason = "UnknownError"
                    }
                    callback?(name, nil, reason)
                }
            }
            else {
                callback?(name, nil, "UnknownError")
            }

            completion.resolve()

            // Remove the temporary command.
            self.remove(callbackID)
        })

        return callbackID
    }

    /// Waits for ready. If ready, sends requests to the JS library.
    func waitForReadyAndSendRequests() {
        guard let webView else { return }

        if !isReady {
            if !waitForReady.wait({ [weak self] in
                self?.waitForReadyAndSendRequests()
            }) {
                print("[Kamome] Waiting for ready has timed out.")
            }
            return
        }

        requests.forEach { try? Messenger.sendRequest($0, with: webView) }

        // Reset
        requests.removeAll()
    }
}
