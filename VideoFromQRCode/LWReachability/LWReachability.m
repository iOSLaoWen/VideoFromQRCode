//
//  LWReachability.m
//  VideoFromQRCode
//
//  Created by LaoWen on 15/12/24.
//  Copyright © 2015年 LaoWen. All rights reserved.
//

#import "LWReachability.h"
#import "Reachability.h"

static LWReachability *lwReachability = nil;
static Reachability *reachability = nil;

@implementation LWReachability

//单例
+ (id)defaultReachability
{
    if (!lwReachability) {
        lwReachability = [[LWReachability alloc]init];
        reachability = [Reachability reachabilityForInternetConnection];
        [reachability startNotifier];
    }
    return lwReachability;
}

//添加网络可达事件观察者
- (void)addObserver:(id)observer selector:(SEL)sel
{
    [[NSNotificationCenter defaultCenter] addObserver:observer selector:sel name:kReachabilityChangedNotification object:nil];
}

//删除网络可达事件观察者
- (void)removeObserver:(id)observer
{
    [[NSNotificationCenter defaultCenter] removeObserver:observer name:kReachabilityChangedNotification object:nil];
}

//判断wifi通不通
- (BOOL)isWifiReachable
{
    return reachability.currentReachabilityStatus == ReachableViaWiFi;
}

//判断移动网络通不通
- (BOOL)isWWANReachable
{
    return reachability.currentReachabilityStatus == ReachableViaWWAN;
}

//判断internet通不通
- (BOOL)isInternetReachable
{
    return reachability.currentReachabilityStatus != NotReachable;
}

@end
