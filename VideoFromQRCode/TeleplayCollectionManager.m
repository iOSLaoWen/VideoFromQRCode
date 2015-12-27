//
//  TeleplayCollectionManager.m
//  VideoFromQRCode
//
//  Created by LaoWen on 15/12/23.
//  Copyright © 2015年 LaoWen. All rights reserved.
//

#import "TeleplayCollectionManager.h"
#import "FMDatabase.h"

static TeleplayCollectionManager *teleplayCollectionManager = nil;

//电视剧列表管理器，存数据库，多表操作
@implementation TeleplayCollectionManager
{
    FMDatabase *_fmdb;
}

//初始化
- (id)init
{
    if (self = [super init]) {
        NSString *dbPath = [NSHomeDirectory() stringByAppendingString:@"/Documents/teleplay.db"];
        NSLog(@"dbPath: %@", dbPath);
        _fmdb = [[FMDatabase alloc]initWithPath:dbPath];
        [_fmdb open];
        
        //建表：
        //因为一部电视剧有多集，所以分成两个表：teleplayNamed表存储电视剧名，teleplayDetail存储每集信息
        
        //建表:电视剧名
        //ID: 主键
        //name: 电视剧名
        NSString *sql = @"create table if not exists teleplayName(ID integer primary key autoincrement, name varchar(256))";
        if (![_fmdb executeUpdate:sql]) {
            NSLog(@"建表teleplayName失败:%@", _fmdb.lastErrorMessage);
            goto exit;
        }
        
        //建表:电视剧详情
        //ID: 主键
        //teleplayID: 外键
        //name: 集名
        //url: 该集网址
        sql = @"create table if not exists teleplayDetail(ID integer primary key autoincrement, teleplayID integer, name varchar(256), url varchar(2048))";
        if (![_fmdb executeUpdate:sql]) {
            NSLog(@"建表teleplayDetail失败:%@", _fmdb.lastErrorMessage);
            goto exit;
        }
    }
exit:
    return self;
}

//单例
+ (id)defaultManager
{
    if (!teleplayCollectionManager) {
        teleplayCollectionManager = [[TeleplayCollectionManager alloc]init];
    }
    return teleplayCollectionManager;
}

//插入电视剧
- (void)insertTeleplayWithTeleplayModel:(TeleplayModel *)teleplayModel
{
    //因为是多表操作，为了保重数据的完整性和一致性，需要用到事务
    [_fmdb beginTransaction];
    @try {
        //首先插入teleplayName表
        NSString *sql = @"insert into teleplayName(name) values(?)";
        if (![_fmdb executeUpdate:sql, teleplayModel.name]) {
            @throw [NSException exceptionWithName:@"InsertTeleplayException" reason:[NSString stringWithFormat:@"插入电视剧名失败:%@ 错误信息:%@", teleplayModel.name, _fmdb.lastErrorMessage] userInfo:nil];
        }
        
        //再插入teleplayDetail表
        sql = @"insert into teleplayDetail(teleplayID, name, url) values(?, ?, ?)";
        unsigned long long teleplayID = _fmdb.lastInsertRowId;
        for (TeleplaySectionModel *section in teleplayModel.sections) {
            if (![_fmdb executeUpdate:sql, @(teleplayID), section.name, section.url]) {
                @throw [NSException exceptionWithName:@"InsertTeleplayException" reason:[NSString stringWithFormat:@"插入电视剧详情失败:%@", _fmdb.lastErrorMessage] userInfo:nil];
            }
        }
    }
    @catch (NSException *exception) {
        NSLog(@"%@", exception.reason);
        [_fmdb rollback];//数据库回滚，取消事务
    }
    @finally {
        [_fmdb commit];//提交事务
    }
}

//删除电视剧
- (void)deleteTeleplayWithID:(unsigned long long)ID
{
    [_fmdb beginTransaction];//开启事务
    @try {
        //从电视剧名表teleplayName删除数据
        NSString *sql = @"delete from teleplayName where ID = ?";
        if (![_fmdb executeUpdate:sql, @(ID)]) {
            @throw [NSException exceptionWithName:@"DeleteTelepalyException" reason:[NSString stringWithFormat:@"删除表teleplayName异常:%@", _fmdb.lastErrorMessage] userInfo:nil];
        }
        
        //从电视剧详情表teleplayDetail
        sql = @"delete from teleplayDetail where teleplayID = ?";
        if (![_fmdb executeUpdate:sql, @(ID)]) {
            @throw [NSException exceptionWithName:@"DeleteTelepalyException" reason:[NSString stringWithFormat:@"删除表teleplayDetail异常:%@", _fmdb.lastErrorMessage] userInfo:nil];
        }
    }
    @catch (NSException *exception) {
        [_fmdb rollback];//取消事务回滚数据
        NSLog(@"%@", exception.reason);
    }
    @finally {
        [_fmdb commit];//提交事务
    }
}

//所有电视剧名列表，详细信息为空
- (NSArray<NSString *> *)allTeleplays
{
    NSString *sql = @"select * from teleplayName";
    FMResultSet *resultSet = [_fmdb executeQuery:sql];
    NSMutableArray *result = [NSMutableArray array];
    while ([resultSet next]) {
        TeleplayModel *model = [[TeleplayModel alloc]init];
        model.name = [resultSet stringForColumn:@"name"];
        model.ID = [resultSet unsignedLongLongIntForColumn:@"ID"];
        [result addObject:model];
    }
    return result;
}

//获取指定电视剧的详情，即每集的信息
- (NSArray<TeleplaySectionModel *> *)detailForTeleplayID:(unsigned long long)teleplayID
{
    NSString *sql = @"select * from teleplayDetail where teleplayID = ?";
    FMResultSet *resultSet = [_fmdb executeQuery:sql, @(teleplayID)];
    NSMutableArray *result = [NSMutableArray array];
    while ([resultSet next]) {
        TeleplaySectionModel *sectionModel = [[TeleplaySectionModel alloc]init];
        sectionModel.ID = [resultSet unsignedLongLongIntForColumn:@"ID"];
        sectionModel.name = [resultSet stringForColumn:@"name"];
        sectionModel.url = [resultSet stringForColumn:@"url"];
        [result addObject:sectionModel];
    }
    return result;
}

//获取指定名字的电影剧，模拟查询所以结果为数组
- (NSArray<TeleplayModel *> *)teleplaysWithName:(NSString *)name
{
    NSLog(@"%s暂未实现", __FUNCTION__);
    return nil;
}


@end
