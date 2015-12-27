//
//  NSString+Path.h
//  PlayingByDownloading
//
//  Created by LaoWen on 15/12/6.
//  Copyright © 2015年 LaoWen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Path)

//从路径中获取文件名
- (NSString *)extractFileName;

//从路径中获取文件夹名
- (NSString *)extractDir;

@end
