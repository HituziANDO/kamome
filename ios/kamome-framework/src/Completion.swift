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

open class Completion: Completable {
    private let requestID: String

    private weak var webView: WKWebView?
    private var completed = false

    public init(webView: WKWebView, requestID: String) {
        self.webView = webView
        self.requestID = requestID
    }

    public var isCompleted: Bool {
        completed
    }

    public func resolve() {
        guard !completed, let webView else { return }

        completed = true

        try? Messenger.completeMessage(with: webView, data: nil, for: requestID)
    }

    public func resolve(_ data: [String: Any?]) {
        guard !completed, let webView else { return }

        completed = true

        try? Messenger.completeMessage(with: webView, data: data, for: requestID)
    }

    public func resolve(_ data: [Any?]) {
        guard !completed, let webView else { return }

        completed = true

        try? Messenger.completeMessage(with: webView, data: data, for: requestID)
    }

    public func reject() {
        reject(nil)
    }

    public func reject(_ errorMessage: String?) {
        guard !completed, let webView else { return }

        completed = true

        Messenger.failMessage(with: webView, error: errorMessage, for: requestID)
    }
}
