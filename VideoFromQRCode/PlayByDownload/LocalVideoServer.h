//
//  LocalVideoServer.h
//  PlayingByDownloading
//
//  Created by LaoWen on 15/12/3.
//  Copyright © 2015年 LaoWen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LocalVideoServer : NSObject

@property (atomic, copy) NSString *rootDir;
@property (atomic, assign) NSInteger port;
@property (atomic, retain) NSArray *videoFilesStatus;
//@property (atomic, retain) NSLock *lock;//必须在启动之前赋值
@property (atomic, strong) NSCondition *condition;//必须在启动之前赋值

- (BOOL)start;
- (void)stop;

@end
