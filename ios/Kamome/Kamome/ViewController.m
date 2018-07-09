//
//  ViewController.m
//  Kamome
//
//  Created by Masaki Ando on 2018/07/05.
//  Copyright © 2018年 Hituzi Ando. All rights reserved.
//

@import WebKit;

#import "ViewController.h"

#import <KamomeSDK/KamomeSDK.h>

@interface ViewController ()

@property (nonatomic) WKWebView *webView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    KMMKamome *kamome = [KMMKamome new];

    WKWebViewConfiguration *configuration = [WKWebViewConfiguration new];
    configuration.userContentController = kamome.userContentController;
    self.webView = [[WKWebView alloc] initWithFrame:self.view.frame configuration:configuration];

    [kamome setWebView:self.webView];

    [kamome addCommand:[KMMCommand commandWithName:@"echo" handler:^(NSDictionary *data, KMMCompletion *completion) {
        [completion completeWithData:@{ @"message": data[@"message"] }];
    }]];

    NSURL *htmlUrl = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"index" ofType:@"html" inDirectory:@"www"]];
    [self.webView loadFileURL:htmlUrl allowingReadAccessToURL:htmlUrl];
    [self.view addSubview:self.webView];
}

@end
