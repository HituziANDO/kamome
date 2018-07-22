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

- (void)addCommand:(KMMCommand *)command {
    [self.userContentController addCommand:command];
}

- (void)sendMessageWithDictionary:(NSDictionary *)data forName:(NSString *)name {
    [KMMMessenger sendMessageWithWebView:self.webView data:data forName:name];
}

- (void)sendMessageWithArray:(NSArray *)data forName:(NSString *)name {
    [KMMMessenger sendMessageWithWebView:self.webView data:data forName:name];
}

@end
