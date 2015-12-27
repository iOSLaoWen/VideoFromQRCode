//
//  TeleplayListController.h
//  VideoFromQRCode
//
//  Created by LaoWen on 15/12/23.
//  Copyright © 2015年 LaoWen. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TeleplayListController : UIViewController<UITableViewDataSource, UITableViewDelegate>
- (IBAction)onBtnReadQRCodeClicked:(id)sender;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *btnScanQRCode;

- (void)onRemoteNotification:(NSDictionary *)info;

@end
