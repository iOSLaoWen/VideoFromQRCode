//
//  LoginViewController.m
//  VideoFromQRCode
//
//  Created by LaoWen on 15/12/26.
//  Copyright © 2015年 LaoWen. All rights reserved.
//

#import "LoginViewController.h"
#import "LWHttpConnection.h"
#import "urls.h"
#import "MBProgressHUDManager.h"

@interface LoginViewController ()
@property (weak, nonatomic) IBOutlet UITextField *textUserName;
@property (weak, nonatomic) IBOutlet UITextField *textPassword;
- (IBAction)onBtnOKClicked:(id)sender;
- (IBAction)onBtnCancelClicked:(id)sender;

@end

@implementation LoginViewController
{
    MBProgressHUDManager *_hudManager;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _hudManager = [[MBProgressHUDManager alloc]initWithView:self.view];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)onBtnOKClicked:(id)sender {
    [LWHttpConnection POST:kLoginUrl parameters:@{@"UserName": self.textUserName.text,
                                                  @"Password": self.textPassword.text
    } success:^(LWHttpConnection *http, NSData *data) {
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
        //TODO:保存token
        if ([dict[@"code"] isEqualToString:@"success"]) {
            [_hudManager showSuccessWithMessage:@"登录成功" duration:3 complection:^{
                [self.navigationController popViewControllerAnimated:YES];
            }];
        } else {
            [_hudManager showErrorWithMessage:@"登录失败" duration:3];
        }

    } failure:^(LWHttpConnection *http, NSError *error) {
        [_hudManager showErrorWithMessage:@"登录出错" duration:3];
    }];
}

- (IBAction)onBtnCancelClicked:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}
@end
