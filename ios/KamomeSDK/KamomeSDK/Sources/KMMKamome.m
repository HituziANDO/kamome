//
// Created by Masaki Ando on 2018/07/08.
// Copyright (c) 2018 Hituzi Ando. All rights reserved.
//

#import "KMMKamome.h"
#import "KMMUserContentController.h"
#import "KMMCommand.h"
#import "KMMMessenger.h"

@interface KMMKamome ()

@property (nonatomic, weak) id webView;
@property (nonatomic) KMMUserContentController *userContentController;

@end

@implementation KMMKamome

- (instancetype)init {
    self = [super init];

    if (self) {
        _userContentController = [KMMUserContentController new];
    }

    return self;
}

- (void)setWebView:(id)webView {
    _webView = webView;
    self.userContentController.webView = webView;
}

- (instancetype)addCommand:(KMMCommand *)command {
    [self.userContentController addCommand:command];

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
        [[KMMMessenger sharedMessenger] sendMessageWithWebView:self.webView data:data block:nil callbackId:nil forName:name];
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
        [[KMMMessenger sharedMessenger] sendMessageWithWebView:self.webView data:data block:nil callbackId:nil forName:name];
    }
}

@end
