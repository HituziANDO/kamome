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
FOUNDATION_EXTERN NSString *const KMMErrorDomain;

/**
 * Receives a result from the JavaScript receiver when it processed a task of a command.
 * An error occurs when the native client receives it from the JavaScript receiver, otherwise it will be null.
 */
typedef void (^KMMSendMessageCallback)(NSString *commandName, id _Nullable result, NSError *_Nullable error);

typedef NS_ENUM(NSInteger, KMMHowToHandleNonExistentCommand) {
    /**
     * Anyway resolved passing null.
     */
        KMMHowToHandleNonExistentCommandResolved,
    /**
     * Always rejected and passing an error message.
     */
        KMMHowToHandleNonExistentCommandRejected,
    /**
     * Always raises an exception.
     */
        KMMHowToHandleNonExistentCommandException
};

@interface KMMKamome : NSObject <WKScriptMessageHandler>

@property (nonatomic, readonly) WKUserContentController *contentController;
/**
 * How to handle non-existent command.
 */
@property (nonatomic) KMMHowToHandleNonExistentCommand howToHandleNonExistentCommand;

/**
 * Creates a Kamome object and a webView object of specified class initialized by Kamome.
 *
 * @param webView Returns a webView object created by Kamome.
 * @param webViewClass A webView's class.
 * @param frame A webView's frame.
 * @return A Kamome object.
 */
+ (instancetype)createInstanceAndWebView:(id _Nullable *_Nullable)webView
                                   class:(Class)webViewClass
                                   frame:(CGRect)frame NS_SWIFT_NAME(create(webView:class:frame:));
/**
 * Sets a webView using this Kamome object.
 */
- (void)setWebView:(__kindof WKWebView *)webView;
/**
 * Adds a command called by JavaScript code.
 *
 * @param command A command object.
 * @return Self.
 */
- (instancetype)addCommand:(KMMCommand *)command;
/**
 * Removes a command of specified name.
 *
 * @param name A command name that you will remove.
 */
- (void)removeCommandForName:(NSString *)name NS_SWIFT_NAME(removeCommand(name:));
/**
 * Sends a message to the JavaScript receiver.
 *
 * @param name A command name.
 * @param block A callback.
 */
- (void)sendMessageForName:(NSString *)name
                     block:(nullable KMMSendMessageCallback)block NS_SWIFT_NAME(sendMessage(name:block:));
/**
 * Sends a message with data as NSDictionary to the JavaScript receiver.
 *
 * @param data A data as NSDictionary.
 * @param name A command name.
 * @param block A callback.
 */
- (void)sendMessageWithDictionary:(nullable NSDictionary *)data
                          forName:(NSString *)name
                            block:(nullable KMMSendMessageCallback)block NS_SWIFT_NAME(sendMessage(with:name:block:));
/**
 * Sends a message with data as NSArray to the JavaScript receiver.
 *
 * @param data A data as NSArray.
 * @param name A command name.
 * @param block A callback.
 */
- (void)sendMessageWithArray:(nullable NSArray *)data
                     forName:(NSString *)name
                       block:(nullable KMMSendMessageCallback)block NS_SWIFT_NAME(sendMessage(with:name:block:));
/**
 * Executes a command to the native receiver.
 *
 * @param name A command name.
 * @param callback A callback.
 */
- (void)executeCommand:(NSString *)name
              callback:(nullable void (^)(id _Nullable result, NSString *_Nullable errorMessage))callback
NS_SWIFT_NAME(executeCommand(_:callback:));
/**
 * Executes a command with data to the native receiver.
 *
 * @param name A command name.
 * @param data A data as NSDictionary.
 * @param callback A callback.
 */
- (void)executeCommand:(NSString *)name
              withData:(nullable NSDictionary *)data
              callback:(nullable void (^)(id _Nullable result, NSString *_Nullable errorMessage))callback
NS_SWIFT_NAME(executeCommand(_:data:callback:));

@end

NS_ASSUME_NONNULL_END
