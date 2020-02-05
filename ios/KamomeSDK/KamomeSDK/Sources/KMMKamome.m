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

#import "KMMKamome.h"
#import "KMMCommand.h"
#import "KMMCompletion.h"
#import "KMMException.h"
#import "KMMLocalCompletion.h"
#import "KMMMessenger.h"

NSString *const KMMScriptMessageHandlerName = @"kamomeSend";
NSString *const KMMErrorDomain = @"jp.hituzi.KamomeSDKError";

@interface KMMCommand ()

- (void)execute:(nullable NSDictionary *)data withCompletion:(id <KMMCompleting>)completion;

@end

@interface KMMKamome ()

@property (nonatomic, weak) __kindof WKWebView *webView;
@property (nonatomic) WKUserContentController *contentController;
@property (nonatomic, copy) NSMutableDictionary<NSString *, KMMCommand *> *commands;

@end

@implementation KMMKamome

- (instancetype)init {
    self = [super init];

    if (self) {
        _contentController = [WKUserContentController new];
        [_contentController addScriptMessageHandler:self name:KMMScriptMessageHandlerName];
        _howToHandleNonExistentCommand = KMMHowToHandleNonExistentCommandResolved;
        _commands = [NSMutableDictionary new];
    }

    return self;
}

#pragma mark - WKScriptMessageHandler

- (void)userContentController:(WKUserContentController *)userContentController
      didReceiveScriptMessage:(WKScriptMessage *)message {
    if (![message.name isEqualToString:KMMScriptMessageHandlerName] || [message.body length] <= 0) {
        return;
    }

    NSDictionary *data = [NSJSONSerialization JSONObjectWithData:[message.body dataUsingEncoding:NSUTF8StringEncoding]
                                                         options:NSJSONReadingAllowFragments
                                                           error:nil];

    NSDictionary *params = data[@"data"] != [NSNull null] ? data[@"data"] : nil;
    KMMCompletion *completion = [[KMMCompletion alloc] initWithWebView:self.webView requestId:data[@"id"]];
    [self handleCommand:data[@"name"] withData:params completion:completion];
}

#pragma mark - public method

+ (instancetype)createInstanceAndWebView:(id _Nullable *_Nullable)webView
                                   class:(Class)webViewClass
                                   frame:(CGRect)frame {

    KMMKamome *kamome = [KMMKamome new];
    WKWebViewConfiguration *config = [WKWebViewConfiguration new];
    config.userContentController = kamome.contentController;
    SEL sel = NSSelectorFromString(@"initWithFrame:configuration:");
    IMP method = [webViewClass instanceMethodForSelector:sel];
    id (*func)(id, SEL, CGRect, WKWebViewConfiguration *) = (void *) method;
    *webView = func([webViewClass alloc], sel, frame, config);
    kamome.webView = *webView;
    return kamome;
}

- (void)setWebView:(__kindof WKWebView *)webView {
    _webView = webView;
}

- (instancetype)addCommand:(KMMCommand *)command {
    if (command) {
        self.commands[command.name] = command;
    }

    return self;
}

- (void)removeCommandForName:(NSString *)name {
    if (self.commands[name]) {
        [self.commands removeObjectForKey:name];
    }
}

- (void)sendMessageForName:(NSString *)name block:(nullable KMMSendMessageCallback)block {
    [self sendMessageWithDictionary:nil forName:name block:block];
}

- (void)sendMessageWithDictionary:(nullable NSDictionary *)data
                          forName:(NSString *)name
                            block:(nullable KMMSendMessageCallback)block {

    if (block) {
        NSString *callbackId = [self addSendMessageCallback:block];
        [KMMMessenger sendMessageWithWebView:self.webView data:data callbackId:callbackId forName:name];
    }
    else {
        [KMMMessenger sendMessageWithWebView:self.webView data:data callbackId:nil forName:name];
    }
}

- (void)sendMessageWithArray:(nullable NSArray *)data
                     forName:(NSString *)name
                       block:(nullable KMMSendMessageCallback)block {

    if (block) {
        NSString *callbackId = [self addSendMessageCallback:block];
        [KMMMessenger sendMessageWithWebView:self.webView data:data callbackId:callbackId forName:name];
    }
    else {
        [KMMMessenger sendMessageWithWebView:self.webView data:data callbackId:nil forName:name];
    }
}

- (void)executeCommand:(NSString *)name
              callback:(nullable void (^)(id _Nullable result, NSString *_Nullable errorMessage))callback {

    [self executeCommand:name withData:nil callback:callback];
}

- (void)executeCommand:(NSString *)name
              withData:(nullable NSDictionary *)data
              callback:(nullable void (^)(id _Nullable result, NSString *_Nullable errorMessage))callback {

    [self handleCommand:name withData:data completion:[[KMMLocalCompletion alloc] initWithCallback:callback]];
}

#pragma mark - private method

- (void)handleCommand:(NSString *)name
             withData:(nullable NSDictionary *)data
           completion:(id <KMMCompleting>)completion {

    KMMCommand *command = self.commands[name];

    if (command) {
        [command execute:data withCompletion:completion];
    }
    else {
        switch (self.howToHandleNonExistentCommand) {
            case KMMHowToHandleNonExistentCommandRejected:
                [completion rejectWithErrorMessage:@"CommandNotAdded"];
                break;
            case KMMHowToHandleNonExistentCommandException:
                @throw [KMMException exceptionWithReason:[NSString stringWithFormat:@"%@ command not added.", name]
                                                userInfo:nil];
            default:
                [completion resolve];
        }
    }
}

- (NSString *)addSendMessageCallback:(KMMSendMessageCallback)block {
    NSString *callbackId = [NSUUID UUID].UUIDString;
    __weak typeof(self) weakSelf = self;

    // Add a temporary command receiving a result from the JavaScript handler.
    [self addCommand:[KMMCommand commandWithName:callbackId
                                         handler:^(NSString *commandName,
                                                   NSDictionary *data,
                                                   id <KMMCompleting> completion) {
                                             BOOL success = [data[@"success"] boolValue];

                                             if (success) {
                                                 block(commandName, data[@"result"], nil);
                                             }
                                             else {
                                                 NSError *error = [NSError errorWithDomain:KMMErrorDomain
                                                                                      code:1
                                                                                  userInfo:@{
                                                                                      NSLocalizedFailureReasonErrorKey: data[@"error"] ?: @"UnknownError"
                                                                                  }];
                                                 block(commandName, nil, error);
                                             }

                                             [completion resolve];

                                             // Remove the temporary command.
                                             [weakSelf removeCommandForName:callbackId];
                                         }]];

    return callbackId;
}

@end
