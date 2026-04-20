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
        let id = escapeForJSStringLiteral(requestID)
        if let data {
            if !JSONSerialization.isValidJSONObject(data) {
                throw KamomeError.invalidJSONObject
            }

            let params = String(data: try JSONSerialization.data(withJSONObject: data), encoding: .utf8)!
            run(javaScript: "\(jsObj).onComplete(\(params), '\(id)')", with: webView)
        }
        else {
            run(javaScript: "\(jsObj).onComplete(null, '\(id)')", with: webView)
        }
    }

    static func failMessage(with webView: WKWebView, error: String?, for requestID: String) {
        let id = escapeForJSStringLiteral(requestID)
        if let error {
            let allowed = NSCharacterSet.alphanumerics.union(.init(charactersIn: "-._~"))
            let errMsg = error.addingPercentEncoding(withAllowedCharacters: allowed) ?? error
            run(javaScript: "\(jsObj).onError('\(errMsg)', '\(id)')", with: webView)
        }
        else {
            run(javaScript: "\(jsObj).onError(null, '\(id)')", with: webView)
        }
    }

    static func sendRequest(_ request: Request, with webView: WKWebView) throws {
        let name = escapeForJSStringLiteral(request.name)
        let callbackID = escapeForJSStringLiteral(request.callbackID)
        if let data = request.data {
            if !JSONSerialization.isValidJSONObject(data) {
                throw KamomeError.invalidJSONObject
            }

            let params = String(data: try JSONSerialization.data(withJSONObject: data), encoding: .utf8)!
            run(javaScript: "\(jsObj).onReceive('\(name)', \(params), '\(callbackID)')",
                    with: webView)
        }
        else {
            run(javaScript: "\(jsObj).onReceive('\(name)', null, '\(callbackID)')",
                    with: webView)
        }
    }

    /// Escapes a string for safe interpolation inside a single-quoted JavaScript string literal.
    static func escapeForJSStringLiteral(_ value: String) -> String {
        var result = ""
        result.reserveCapacity(value.count)
        for scalar in value.unicodeScalars {
            switch scalar {
            case "\\": result += "\\\\"
            case "'": result += "\\'"
            case "\"": result += "\\\""
            case "\n": result += "\\n"
            case "\r": result += "\\r"
            case "\t": result += "\\t"
            case "\u{2028}": result += "\\u2028"
            case "\u{2029}": result += "\\u2029"
            default:
                if scalar.value < 0x20 {
                    result += String(format: "\\u%04x", scalar.value)
                } else {
                    result.unicodeScalars.append(scalar)
                }
            }
        }
        return result
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
