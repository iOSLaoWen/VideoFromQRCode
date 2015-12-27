//
//  TeleplayCollectionManager.h
//  VideoFromQRCode
//
//  Created by LaoWen on 15/12/23.
//  Copyright © 2015年 LaoWen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TeleplayModel.h"

//电视剧列表管理器，存数据库，多表操作
@interface TeleplayCollectionManager : NSObject

//初始化
- (id)init;

//单例
+ (id)defaultManager;

//插入电视剧
- (void)insertTeleplayWithTeleplayModel:(TeleplayModel *)teleplayModel;

//删除电视剧
- (void)deleteTeleplayWithID:(unsigned long long)ID;

//所有电视剧名列表，详细信息为空
- (NSArray<TeleplayModel *> *)allTeleplays;

//获取指定电视剧的详情，即每集的信息
- (NSArray<TeleplaySectionModel *> *)detailForTeleplayID:(unsigned long long)teleplayID;

//获取指定名字的电影剧，模拟查询所以结果为数组
- (NSArray<TeleplayModel *> *)teleplaysWithName:(NSString *)name;

@end
