//
// Copyright (c) 2020-present Hituzi Ando. All rights reserved.
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

#import <WebKit/WebKit.h>

#import "KMMConsoleLogAdapter.h"

@implementation KMMDefaultConsoleLogger

- (void)consoleLog:(id)logMessage {
    NSLog(@"%@", logMessage);
}

@end

@interface KMMConsoleLogAdapter () <WKScriptMessageHandler>

@end

@implementation KMMConsoleLogAdapter

static NSString *const kScriptMessageHandlerName = @"kamomeLog";

- (id <KMMConsoleLogging>)logger {
    if (!_logger) {
        _logger = [KMMDefaultConsoleLogger new];
    }
    return _logger;
}

- (void)setToWebView:(WKWebView *)webView {
    [webView.configuration.userContentController addScriptMessageHandler:self
                                                                    name:kScriptMessageHandlerName];

    NSString *jsLog = [NSString stringWithFormat:@"window.console.log = function(msg) { window.webkit.messageHandlers.%@.postMessage(msg); };",
                                                 kScriptMessageHandlerName];
    [webView.configuration.userContentController addUserScript:[[WKUserScript alloc] initWithSource:jsLog
                                                                                      injectionTime:WKUserScriptInjectionTimeAtDocumentStart
                                                                                   forMainFrameOnly:YES]];

    NSString *jsWarn = [NSString stringWithFormat:@"window.console.warn = function(msg) { window.webkit.messageHandlers.%@.postMessage(msg); };",
                                                  kScriptMessageHandlerName];
    [webView.configuration.userContentController addUserScript:[[WKUserScript alloc] initWithSource:jsWarn
                                                                                      injectionTime:WKUserScriptInjectionTimeAtDocumentStart
                                                                                   forMainFrameOnly:YES]];

    NSString *jsError = [NSString stringWithFormat:@"window.console.error = function(msg) { window.webkit.messageHandlers.%@.postMessage(msg); };",
                                                   kScriptMessageHandlerName];
    [webView.configuration.userContentController addUserScript:[[WKUserScript alloc] initWithSource:jsError
                                                                                      injectionTime:WKUserScriptInjectionTimeAtDocumentStart
                                                                                   forMainFrameOnly:YES]];
}

#pragma mark - WKScriptMessageHandler

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if ([message.name isEqualToString:kScriptMessageHandlerName]) {
        [self.logger consoleLog:message.body];
    }
}

@end
