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

class Messenger {
    private static let jsObj = "window.KM"

    static func completeMessage(with webView: WKWebView, data: Any?, for requestID: String) throws {
        if let data {
            if !JSONSerialization.isValidJSONObject(data) {
                throw KamomeError.invalidJSONObject
            }

            let params = String(data: try JSONSerialization.data(withJSONObject: data), encoding: .utf8)!
            run(javaScript: "\(jsObj).onComplete(\(params), '\(requestID)')", with: webView)
        }
        else {
            run(javaScript: "\(jsObj).onComplete(null, '\(requestID)')", with: webView)
        }
    }

    static func failMessage(with webView: WKWebView, error: String?, for requestID: String) {
        if let error {
            let allowed = NSCharacterSet.alphanumerics.union(.init(charactersIn: "-._~"))
            let errMsg = error.addingPercentEncoding(withAllowedCharacters: allowed) ?? error
            run(javaScript: "\(jsObj).onError('\(errMsg)', '\(requestID)')", with: webView)
        }
        else {
            run(javaScript: "\(jsObj).onError(null, '\(requestID)')", with: webView)
        }
    }

    static func sendRequest(_ request: Request, with webView: WKWebView) throws {
        if let data = request.data {
            if !JSONSerialization.isValidJSONObject(data) {
                throw KamomeError.invalidJSONObject
            }

            let params = String(data: try JSONSerialization.data(withJSONObject: data), encoding: .utf8)!
            run(javaScript: "\(jsObj).onReceive('\(request.name)', \(params), '\(request.callbackID)')",
                    with: webView)
        }
        else {
            run(javaScript: "\(jsObj).onReceive('\(request.name)', null, '\(request.callbackID)')",
                    with: webView)
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
