//
//  SinaLoginViewController.m
//  VideoFromQRCode
//
//  Created by LaoWen on 15/12/26.
//  Copyright © 2015年 LaoWen. All rights reserved.
//

#import "SinaLoginViewController.h"
#import "MBProgressHUDManager.h"
#import "LWHttpConnection.h"

@interface SinaLoginViewController ()<UIWebViewDelegate>

@property (weak, nonatomic) IBOutlet UIWebView *webView;

@end

@implementation SinaLoginViewController
{
    MBProgressHUDManager *_hudManager;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _hudManager = [[MBProgressHUDManager alloc]initWithView:self.view];
    
    _webView.delegate = self;
    NSURL* url = [NSURL URLWithString:@"https://api.weibo.com/oauth2/authorize?client_id=643154989&redirect_uri=http://www.baidu.com&response_type=code"];
    NSURLRequest* request = [NSURLRequest requestWithURL:url];
    [_webView loadRequest:request];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSArray* array = [request.URL.absoluteString componentsSeparatedByString:@"?code="];
    if (array.count > 1) {
        NSDictionary *params = @{@"client_id": @"643154989",
                                 @"client_secret": @"ae531b8ee06800012315920200628e62",
                                 @"grant_type": @"authorization_code",
                                 @"code": array[1],
                                 @"redirect_uri": @"http%3a%2f%2fwww.baidu.com"};
        [LWHttpConnection POST:@"https://api.weibo.com/oauth2/access_token" parameters:params success:^(LWHttpConnection *http, NSData *data) {
            NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            NSString *token = dict[@"access_token"];
            NSLog(@"token: %@", token);
            [_hudManager showErrorWithMessage:@"登录成功" duration:2 complection:^{
                [self.navigationController popViewControllerAnimated:YES];
            } ];
        } failure:^(LWHttpConnection *http, NSError *error) {
            NSLog(@"error: %@", error);
        }];
        
        return NO;
    }
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    [_hudManager showIndeterminateWithMessage:@"努力加载网页..."];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [_hudManager hide];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [_hudManager showErrorWithMessage:@"打开网页失败" duration:2 complection:^{
        [self.navigationController popViewControllerAnimated:YES];
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
