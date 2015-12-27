//
//  RegisterViewController.h
//  VideoFromQRCode
//
//  Created by LaoWen on 15/12/26.
//  Copyright © 2015年 LaoWen. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RegisterViewController : UIViewController
@property (weak, nonatomic) IBOutlet UITextField *textUserName;
@property (weak, nonatomic) IBOutlet UIButton *btnHeadImage;
@property (weak, nonatomic) IBOutlet UITextField *textPassword;
- (IBAction)onBtnOKClicked:(id)sender;
- (IBAction)onBtnCancelClicked:(id)sender;
- (IBAction)onBtnHeadImageClicked:(id)sender;

@end
