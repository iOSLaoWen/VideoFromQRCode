//
//  TeleplayModel.h
//  VideoFromQRCode
//
//  Created by LaoWen on 15/12/23.
//  Copyright © 2015年 LaoWen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JSONModel.h"

@protocol TeleplaySectionModel <NSObject>
@end

@interface TeleplaySectionModel : JSONModel

//@property (nonatomic, strong)NSNumber<Optional> *ID;
@property (nonatomic, assign)unsigned long long ID;
@property (nonatomic, strong)NSString *name;//电视剧某集名
@property (nonatomic, strong)NSString *url;//m3u8网址

@end

@interface TeleplayModel : JSONModel

@property (nonatomic, assign)unsigned long long ID;
@property (nonatomic, strong)NSString *name;//电视剧名
@property (nonatomic, strong)NSArray<TeleplaySectionModel> *sections;//各集列表

@end
