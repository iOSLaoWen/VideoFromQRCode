//
//  NSString+Path.m
//  PlayingByDownloading
//
//  Created by LaoWen on 15/12/6.
//  Copyright © 2015年 LaoWen. All rights reserved.
//

#import "NSString+Path.h"

@implementation NSString (Path)

//从路径中获取文件名
- (NSString *)extractFileName
{
    NSRange range = [self rangeOfString:@"/" options:NSBackwardsSearch];
    return [self substringFromIndex:range.location+range.length];
}

//从路径中获取文件夹名
- (NSString *)extractDir
{
    NSRange range = [self rangeOfString:@"/"];
    return [self substringToIndex:range.location];
}
@end
