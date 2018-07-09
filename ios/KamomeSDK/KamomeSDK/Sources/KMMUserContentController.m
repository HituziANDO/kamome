//
// Created by Masaki Ando on 2018/07/07.
// Copyright (c) 2018 Hituzi Ando. All rights reserved.
//

@import WebKit;

#import "KMMUserContentController.h"
#import "KMMCommand.h"
#import "KMMCompletion.h"

@interface KMMUserContentController () <WKScriptMessageHandler>

@property (nonatomic, copy) NSMutableArray *commands;

@end

@implementation KMMUserContentController

static NSString *const kHandlerName = @"kamomeSend";

- (instancetype)init {
    self = [super init];

    if (self) {
        _commands = [NSMutableArray new];

        [self addScriptMessageHandler:self name:kHandlerName];
    }

    return self;
}

- (void)addCommand:(KMMCommand *)command {
    if (command) {
        [self.commands addObject:command];
    }
}

#pragma mark - WKScriptMessageHandler

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if (![message.name isEqualToString:kHandlerName] || [message.body length] <= 0) {
        return;
    }

    NSDictionary *data = [NSJSONSerialization JSONObjectWithData:[message.body dataUsingEncoding:NSUTF8StringEncoding]
                                                         options:NSJSONReadingAllowFragments
                                                           error:nil];

    for (KMMCommand *command in self.commands) {
        if ([command.name isEqualToString:data[@"name"]]) {
            KMMCompletion *completion = [[KMMCompletion alloc] initWithWebView:self.webView name:command.name];
            [command execute:data[@"data"] withCompletion:completion];
        }
    }
}

@end