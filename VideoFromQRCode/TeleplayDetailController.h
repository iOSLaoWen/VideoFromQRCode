//
//  TeleplayDetailController.h
//  VideoFromQRCode
//
//  Created by LaoWen on 15/12/23.
//  Copyright © 2015年 LaoWen. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TeleplayDetailController : UIViewController<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, assign)unsigned long long teleplayID;//电视剧ID
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end
