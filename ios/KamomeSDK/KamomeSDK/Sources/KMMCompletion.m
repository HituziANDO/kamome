//
// Created by Masaki Ando on 2018/07/06.
// Copyright (c) 2018 Hituzi Ando. All rights reserved.
//

@import WebKit;

#import "KMMCompletion.h"
#import "KMMMessenger.h"

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

- (void)complete {
    [self resolve];
}

- (void)completeWithDictionary:(NSDictionary *)data {
    [self resolveWithDictionary:data];
}

- (void)completeWithArray:(NSArray *)data {
    [self resolveWithArray:data];
}

- (void)resolve {
    [self resolveWithDictionary:nil];
}

- (void)resolveWithDictionary:(nullable NSDictionary *)data {
    if (self.completed) {
        return;
    }

    self.completed = YES;

    [[KMMMessenger sharedMessenger] completeMessageWithWebView:self.webView data:data forName:self.name];
}

- (void)resolveWithArray:(nullable NSArray *)data {
    if (self.completed) {
        return;
    }

    self.completed = YES;

    [[KMMMessenger sharedMessenger] completeMessageWithWebView:self.webView data:data forName:self.name];
}

- (void)reject {
    [self rejectWithErrorMessage:nil];
}

- (void)rejectWithErrorMessage:(nullable NSString *)errorMessage {
    if (self.completed) {
        return;
    }

    self.completed = YES;

    [[KMMMessenger sharedMessenger] failMessageWithWebView:self.webView error:errorMessage forName:self.name];
}

@end
