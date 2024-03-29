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

        if let callback {
            callback(nil, nil)
        }
    }

    public func resolve(_ data: [String: Any?]) {
        if completed {
            return
        }

        completed = true

        if let callback {
            callback(data, nil)
        }
    }

    public func resolve(_ data: [Any?]) {
        if completed {
            return
        }

        completed = true

        if let callback {
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

        if let callback {
            callback(nil, errorMessage ?? "Rejected")
        }
    }
}
