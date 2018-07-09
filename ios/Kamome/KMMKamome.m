//
// Created by Masaki Ando on 2018/07/08.
// Copyright (c) 2018 Hituzi Ando. All rights reserved.
//

#import "KMMKamome.h"
#import "KMMUserContentController.h"
#import "KMMCommand.h"

@interface KMMKamome ()

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
    self.userContentController.webView = webView;
}

- (void)addCommand:(KMMCommand *)command {
    [self.userContentController addCommand:command];
}

@end
