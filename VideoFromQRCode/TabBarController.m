//
//  TabBarController.m
//  VideoFromQRCode
//
//  Created by LaoWen on 15/12/26.
//  Copyright © 2015年 LaoWen. All rights reserved.
//

#import "TabBarController.h"
#import "TeleplayListController.h"

@interface TabBarController ()

@end

@implementation TabBarController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    //处理远程推送
    //用通知中心处理远程推送可以减少程序各页面之间的耦合
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(onRemoteNotification:) name:@"RemoteNotification" object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//处理远程推送（通知中心转发）
//收到远程推送时程序哪一个页面为当前页面完全不确定，但收到推送后要进入哪个页面是确定的。本程序假定收到推送后由“电视剧”首页处理(根据推送中的url向服务器请求json并将json中的电视剧添加到电视剧列表--效果跟扫描二维码相同）,TabBarController(应用的根视图控制器)将标签0（电视剧标签）置为当前页面，并pop到其根，然后调用相应方法
//
- (void)onRemoteNotification:(NSNotification *)notify
{
    NSLog(@"TabbarController收到远程推送通知:%@", notify.userInfo);
    self.selectedIndex = 0;
    UINavigationController *nav0 = self.viewControllers[0];
    [nav0 popToRootViewControllerAnimated:YES];
    TeleplayListController *teleplayListCtrl = nav0.viewControllers[0];
    [teleplayListCtrl onRemoteNotification:notify.userInfo];
}

@end
