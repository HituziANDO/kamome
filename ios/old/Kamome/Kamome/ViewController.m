//
//  ViewController.m
//  Kamome
//
//  Copyright (c) 2020 Hituzi Ando. All rights reserved.
//

#import <WebKit/WebKit.h>
#import <KamomeSDK/KamomeSDK.h>

#import "ViewController.h"

@interface ViewController ()

@property (nonatomic) UIButton *sendButton;
@property (nonatomic) WKWebView *webView;
@property (nonatomic) KMMKamome *kamome;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Create the Kamome object with default webView.
    WKWebView *webView = nil;
    self.kamome = [KMMKamome createInstanceAndWebView:&webView class:[WKWebView class] frame:self.view.frame];
    self.webView = webView;

    // Create the Kamome object for a customized webView.
//    self.kamome = [KMMKamome new];
//
//    WKUserContentController *userContentController = [WKUserContentController new];
//    [userContentController addScriptMessageHandler:self.kamome name:KMMScriptMessageHandlerName];
//    WKWebViewConfiguration *configuration = [WKWebViewConfiguration new];
//    configuration.userContentController = userContentController;
//    self.webView = [[WKWebView alloc] initWithFrame:self.view.frame configuration:configuration];
//
//    [self.kamome setWebView:self.webView];

    [self.kamome addCommand:[KMMCommand commandWithName:@"echo"
                                                handler:^(NSString *_Nonnull commandName,
                                                          NSDictionary *_Nullable data,
                                                          id <KMMCompleting> _Nonnull completion) {
                                                    // Received `echo` command.
                                                    // Then send resolved result to the JavaScript callback function.
                                                    [completion resolveWithDictionary:@{ @"message": data[@"message"] }];
                                                }]];

    [self.kamome addCommand:[KMMCommand commandWithName:@"echoError"
                                                handler:^(NSString *_Nonnull commandName,
                                                          NSDictionary *_Nullable data,
                                                          id <KMMCompleting> _Nonnull completion) {
                                                    // Send rejected result if failed.
                                                    [completion rejectWithErrorMessage:@"Echo Error!"];
                                                }]];

    [self.kamome addCommand:[KMMCommand commandWithName:@"tooLong"
                                                handler:^(NSString *_Nonnull commandName,
                                                          NSDictionary *_Nullable data,
                                                          id <KMMCompleting> _Nonnull completion) {
                                                    // Too long process...
                                                    [NSTimer scheduledTimerWithTimeInterval:30.0
                                                                                    repeats:NO
                                                                                      block:^(NSTimer *timer) {
                                                                                          [completion resolve];
                                                                                      }];
                                                }]];

    [self.kamome addCommand:[KMMCommand commandWithName:@"getUser"
                                                handler:^(NSString *_Nonnull commandName,
                                                          NSDictionary *_Nullable data,
                                                          id <KMMCompleting> _Nonnull completion) {
                                                    [completion resolveWithDictionary:@{ @"name": @"Brad" }];
                                                }]];

    [self.kamome addCommand:[KMMCommand commandWithName:@"getScore"
                                                handler:^(NSString *_Nonnull commandName,
                                                          NSDictionary *_Nullable data,
                                                          id <KMMCompleting> _Nonnull completion) {
                                                    [completion resolveWithDictionary:@{ @"score": @88, @"rank": @2 }];
                                                }]];

    [self.kamome addCommand:[KMMCommand commandWithName:@"getAvg"
                                                handler:^(NSString *_Nonnull commandName,
                                                          NSDictionary *_Nullable data,
                                                          id <KMMCompleting> _Nonnull completion) {
                                                    [completion resolveWithDictionary:@{ @"avg": @68 }];
                                                }]];

    self.kamome.howToHandleNonExistentCommand = KMMHowToHandleNonExistentCommandRejected;

    // Option: Set console.log/.warn/.error adapter.
    [[KMMConsoleLogAdapter new] setToWebView:self.webView];

    NSURL *htmlURL = [[NSBundle mainBundle] URLForResource:@"index" withExtension:@"html" subdirectory:@"www"];
    [self.webView loadFileURL:htmlURL allowingReadAccessToURL:htmlURL];
    [self.view addSubview:self.webView];
    [self.view sendSubviewToBack:self.webView];

    self.sendButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 200.f, 44.f)];
    self.sendButton.backgroundColor = UIColor.purpleColor;
    self.sendButton.layer.cornerRadius = 22.f;
    self.sendButton.layer.shadowColor = UIColor.blackColor.CGColor;
    self.sendButton.layer.shadowOpacity = .4f;
    self.sendButton.layer.shadowOffset = CGSizeMake(0, 4.f);
    [self.sendButton setTitle:@"Send Data to Web" forState:UIControlStateNormal];
    [self.sendButton addTarget:self action:@selector(sendButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.sendButton];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];

    self.sendButton.center = CGPointMake(self.view.center.x, self.view.frame.size.height - 70.f);
}

- (void)sendButtonPressed:(id)sender {
    // Send a data to JavaScript.
    [self.kamome sendMessageWithDictionary:@{ @"greeting": @"Hello! by ObjC" }
                                   forName:@"greeting"
                                     block:^(NSString *commandName, id _Nullable result, NSError *_Nullable error) {
                                         // Received a result from the JS code.
                                         NSLog(@"result: %@", result);
                                     }];
}

@end
