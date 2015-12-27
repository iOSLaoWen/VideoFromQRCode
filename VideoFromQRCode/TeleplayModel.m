//
//  TeleplayModel.m
//  VideoFromQRCode
//
//  Created by LaoWen on 15/12/23.
//  Copyright © 2015年 LaoWen. All rights reserved.
//

#import "TeleplayModel.h"

@implementation TeleplaySectionModel

- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
    
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"name: %@\nurl: %@", _name, _url];
}

@end

@implementation TeleplayModel

- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
    
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"name: %@ sections:{%@\n}", _name, _sections];
}

@end
