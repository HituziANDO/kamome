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

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@class KMMCommand;

FOUNDATION_EXTERN NSString *const KMMScriptMessageHandlerName;

@interface KMMKamome : NSObject <WKScriptMessageHandler>

@property (nonatomic, readonly) WKUserContentController *contentController;

/**
 * Creates a KMMKamome object and default webView object of specified class initialized by Kamome.
 *
 * @param webView Returns a webView object created by Kamome.
 * @param webViewClass A webView's class.
 * @param frame A webView's frame.
 * @return A KMMKamome object.
 */
+ (instancetype)createInstanceAndWebView:(id *)webView
                                   class:(Class)webViewClass
                                   frame:(CGRect)frame NS_SWIFT_NAME(create(webView:class:frame:));

- (void)setWebView:(id)webView;

- (instancetype)addCommand:(KMMCommand *)command;

- (void)sendMessageWithBlock:(nullable void (^)(id _Nullable result))block
                     forName:(NSString *)name DEPRECATED_MSG_ATTRIBUTE("Uses `sendMessageForName:block:` method.");

- (void)sendMessageWithDictionary:(nullable NSDictionary *)data
                            block:(nullable void (^)(id _Nullable result))block
                          forName:(NSString *)name DEPRECATED_MSG_ATTRIBUTE(
    "Uses `sendMessageWithDictionary:forName:block:` method.");

- (void)sendMessageWithArray:(nullable NSArray *)data
                       block:(nullable void (^)(id _Nullable result))block
                     forName:(NSString *)name DEPRECATED_MSG_ATTRIBUTE(
    "Uses `sendMessageWithArray:forName:block:` method.");

- (void)sendMessageForName:(NSString *)name
                     block:(nullable void (^)(id _Nullable result))block NS_SWIFT_NAME(sendMessage(name:block:));

- (void)sendMessageWithDictionary:(nullable NSDictionary *)data
                          forName:(NSString *)name
                            block:(nullable void (^)(id _Nullable result))block NS_SWIFT_NAME(sendMessage(dictionary:name:block:));

- (void)sendMessageWithArray:(nullable NSArray *)data
                     forName:(NSString *)name
                       block:(nullable void (^)(id _Nullable result))block NS_SWIFT_NAME(sendMessage(array:name:block:));

@end

NS_ASSUME_NONNULL_END
