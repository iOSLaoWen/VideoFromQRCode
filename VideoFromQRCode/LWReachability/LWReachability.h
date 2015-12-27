//
//  LWReachability.h
//  VideoFromQRCode
//
//  Created by LaoWen on 15/12/24.
//  Copyright © 2015年 LaoWen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LWReachability : NSObject

//单例
+ (id)defaultReachability;

//添加网络可达事件观察者
- (void)addObserver:(id)observer selector:(SEL)sel;

//删除网络可达事件观察者
- (void)removeObserver:(id)observer;

//判断wifi通不通
- (BOOL)isWifiReachable;

//判断移动网络通不通
- (BOOL)isWWANReachable;

//判断internet通不通
- (BOOL)isInternetReachable;

@end
