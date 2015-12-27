//
//  VideoDownloader.h
//  PlayingByDownloading
//
//  Created by LaoWen on 15/12/6.
//  Copyright © 2015年 LaoWen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VideoDownloader : NSObject

- (void)startWithStrUrl:(NSString *)strUrl;
- (NSString *)m3u8LocalUrl:(NSString *)strUrl;

@end
