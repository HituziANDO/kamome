//
// Created by Masaki Ando on 2018/07/06.
// Copyright (c) 2018 Hituzi Ando. All rights reserved.
//

@import WebKit;

#import "KMMCompletion.h"
#import "KMMMessenger.h"
#import "KMMException.h"

@interface KMMCompletion ()

@property (nonatomic, weak) id webView;
@property (nonatomic, copy) NSString *name;
@property (nonatomic) BOOL completed;

@end

@implementation KMMCompletion

- (instancetype)initWithWebView:(id)webView name:(NSString *)name {
    self = [super init];

    if (self) {
        _webView = webView;
        _name = name;
    }

    return self;
}

- (void)completeWithData:(NSDictionary *)data {
    if (self.completed) {
        return;
    }

    self.completed = YES;

    [KMMMessenger sendMessageWithWebView:self.webView data:data forName:self.name];
}

@end
