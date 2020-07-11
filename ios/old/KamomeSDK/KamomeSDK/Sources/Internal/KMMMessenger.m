//
// Copyright (c) 2018-present Hituzi Ando. All rights reserved.
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

#import "KMMMessenger.h"
#import "KMMException.h"

@implementation KMMMessenger

+ (void)completeMessageWithWebView:(__kindof WKWebView *)webView
                              data:(nullable id)data
                      forRequestId:(NSString *)requestId {

    if (data) {
        if (![NSJSONSerialization isValidJSONObject:data]) {
            @throw [KMMException exceptionWithReason:@"data is not valid." userInfo:nil];
        }

        NSString *params = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:data
                                                                                          options:0
                                                                                            error:nil]
                                                 encoding:NSUTF8StringEncoding];
        [self runJavaScript:[NSString stringWithFormat:@"window.Kamome.onComplete('%@', '%@')", params, requestId]
                withWebView:webView];
    }
    else {
        [self runJavaScript:[NSString stringWithFormat:@"window.Kamome.onComplete(null, '%@')", requestId]
                withWebView:webView];
    }
}

+ (void)failMessageWithWebView:(__kindof WKWebView *)webView
                         error:(nullable NSString *)error
                  forRequestId:(NSString *)requestId {

    if (error) {
        [self runJavaScript:[NSString stringWithFormat:@"window.Kamome.onError('%@', '%@')", error, requestId]
                withWebView:webView];
    }
    else {
        [self runJavaScript:[NSString stringWithFormat:@"window.Kamome.onError(null, '%@')", requestId]
                withWebView:webView];
    }
}

// TODO: kamome.jsがロード完了していないときの処理
+ (void)sendMessageWithWebView:(__kindof WKWebView *)webView
                          data:(nullable id)data
                    callbackId:(nullable NSString *)callbackId
                       forName:(NSString *)name {

    if (data) {
        if (![NSJSONSerialization isValidJSONObject:data]) {
            @throw [KMMException exceptionWithReason:@"data is not valid." userInfo:nil];
        }

        NSString *params = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:data
                                                                                          options:0
                                                                                            error:nil]
                                                 encoding:NSUTF8StringEncoding];

        if (callbackId) {
            [self runJavaScript:[NSString stringWithFormat:@"window.Kamome.onReceive('%@', '%@', '%@')",
                                                           name,
                                                           params,
                                                           callbackId]
                    withWebView:webView];
        }
        else {
            [self runJavaScript:[NSString stringWithFormat:@"window.Kamome.onReceive('%@', '%@', null)", name, params]
                    withWebView:webView];
        }
    }
    else {
        if (callbackId) {
            [self runJavaScript:[NSString stringWithFormat:@"window.Kamome.onReceive('%@', null, '%@')",
                                                           name,
                                                           callbackId]
                    withWebView:webView];
        }
        else {
            [self runJavaScript:[NSString stringWithFormat:@"window.Kamome.onReceive('%@', null, null)", name]
                    withWebView:webView];
        }
    }
}

+ (void)runJavaScript:(NSString *)js withWebView:(__kindof WKWebView *)webView {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (webView) {
            [webView evaluateJavaScript:js completionHandler:^(id value, NSError *error) {
                if (error) {
                    NSLog(@"[Kamome] ERROR: %@ %@", error.localizedDescription, error.userInfo);
                }
            }];
        }
        else {
            @throw [KMMException exceptionWithReason:@"The webView is nil." userInfo:nil];
        }
    });
}

@end
