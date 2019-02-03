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
#import "KMMUserContentController.h"
#import "KMMCommand.h"
#import "KMMCompletion.h"
#import "KMMMessenger.h"

NSString *const KMMScriptMessageHandlerName = @"kamomeSend";

@interface KMMKamome ()

@property (nonatomic, weak) id webView;
@property (nonatomic) KMMUserContentController *userContentController;
@property (nonatomic, copy) NSMutableArray<KMMCommand *> *commands;

@end

@implementation KMMKamome

- (instancetype)init {
    self = [super init];

    if (self) {
        _userContentController = [KMMUserContentController new];
        [_userContentController addScriptMessageHandler:self name:KMMScriptMessageHandlerName];
        _commands = [NSMutableArray new];
    }

    return self;
}

#pragma mark - WKScriptMessageHandler

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if (![message.name isEqualToString:KMMScriptMessageHandlerName] || [message.body length] <= 0) {
        return;
    }

    NSDictionary *data = [NSJSONSerialization JSONObjectWithData:[message.body dataUsingEncoding:NSUTF8StringEncoding]
                                                         options:NSJSONReadingAllowFragments
                                                           error:nil];
    KMMCommand *command = nil;

    for (KMMCommand *cmd in self.commands) {
        if ([cmd.name isEqualToString:data[@"name"]]) {
            command = cmd;
            break;
        }
    }

    KMMCompletion *completion = [[KMMCompletion alloc] initWithWebView:self.webView name:data[@"name"]];

    if (command) {
        [command execute:data[@"data"] withCompletion:completion];
    }
    else {
        [completion resolve];
    }
}

#pragma mark - public method

+ (instancetype)createInstanceAndWebView:(WKWebView **)webView withFrame:(CGRect)frame {
    KMMKamome *kamome = [KMMKamome new];

    WKUserContentController *userContentController = [WKUserContentController new];
    [userContentController addScriptMessageHandler:kamome name:KMMScriptMessageHandlerName];

    WKWebViewConfiguration *configuration = [WKWebViewConfiguration new];
    configuration.userContentController = userContentController;

    *webView = [[WKWebView alloc] initWithFrame:frame configuration:configuration];
    kamome.webView = *webView;

    return kamome;
}

- (void)setWebView:(id)webView {
    _webView = webView;
}

- (instancetype)addCommand:(KMMCommand *)command {
    if (command) {
        [self.commands addObject:command];
    }

    return self;
}

- (void)sendMessageWithBlock:(nullable void (^)(id _Nullable))block forName:(NSString *)name {
    [self sendMessageWithDictionary:nil block:block forName:name];
}

- (void)sendMessageWithDictionary:(nullable NSDictionary *)data block:(nullable void (^)(id _Nullable))block forName:(NSString *)name {
    if (block) {
        [[KMMMessenger sharedMessenger] sendMessageWithWebView:self.webView
                                                          data:data
                                                         block:block
                                                    callbackId:[NSUUID UUID].UUIDString
                                                       forName:name];
    }
    else {
        [[KMMMessenger sharedMessenger] sendMessageWithWebView:self.webView
                                                          data:data
                                                         block:nil
                                                    callbackId:nil
                                                       forName:name];
    }
}

- (void)sendMessageWithArray:(nullable NSArray *)data block:(nullable void (^)(id _Nullable))block forName:(NSString *)name {
    if (block) {
        [[KMMMessenger sharedMessenger] sendMessageWithWebView:self.webView
                                                          data:data
                                                         block:block
                                                    callbackId:[NSUUID UUID].UUIDString
                                                       forName:name];
    }
    else {
        [[KMMMessenger sharedMessenger] sendMessageWithWebView:self.webView
                                                          data:data
                                                         block:nil
                                                    callbackId:nil
                                                       forName:name];
    }
}

@end
