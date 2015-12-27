//
//  RegisterViewController.m
//  VideoFromQRCode
//
//  Created by LaoWen on 15/12/26.
//  Copyright © 2015年 LaoWen. All rights reserved.
//

#import "RegisterViewController.h"
#import "LWHttpConnection.h"
#import "urls.h"
#import "MBProgressHUDManager.h"

@interface RegisterViewController ()<UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@end

@implementation RegisterViewController
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
    [LWHttpConnection POST:kRegisterUrl
                parameters:@{@"UserName": self.textUserName.text,
                             @"Password": self.textPassword.text} constructingBodyWithBlock:^(LWMultipartFormData *formData) {
        UIImage *headImage = [self.btnHeadImage backgroundImageForState:UIControlStateNormal];
        NSData *data = UIImagePNGRepresentation(headImage);
        [formData appendPartWithFileData:data name:@"headImage" fileName:@"abc.png" mimeType:@"image/png"];
        
    } success:^(LWHttpConnection *http, NSData *data) {
        //NSLog(@"data:%s", data.bytes);
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
        if ([dict[@"code"] isEqualToString:@"success"]) {
            [_hudManager showSuccessWithMessage:@"注册成功" duration:3 complection:^{
                [self.navigationController popViewControllerAnimated:YES];
            }];
        } else {
            [_hudManager showErrorWithMessage:@"注册失败" duration:3];
        }
    } failure:^(LWHttpConnection *http, NSError *error) {
        [_hudManager showErrorWithMessage:@"注册出错" duration:3];
    }];
}

- (IBAction)onBtnCancelClicked:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)onBtnHeadImageClicked:(id)sender {
    UIImagePickerController *picker = [[UIImagePickerController alloc]init];
    picker.delegate = self;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.allowsEditing = YES;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    [picker dismissViewControllerAnimated:YES completion:nil];
    UIImage *headImage = info[UIImagePickerControllerEditedImage];
    [self.btnHeadImage setBackgroundImage:headImage forState:UIControlStateNormal];
    self.btnHeadImage.tag = 1;//表示已选择同像
}

@end
