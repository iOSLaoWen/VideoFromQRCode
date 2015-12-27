//
//  LWQRCodeReadController.h
//  LWQRCodeReaderDemo
//
//  Created by LaoWen on 15/12/22.
//  Copyright © 2015年 LaoWen. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LWQRCodeReadController : UIViewController

//读二维成功时调用此block
@property (nonatomic, copy)void (^onSuccess)(NSString *qrCode);

- (id)initWithBlock:(void(^)(NSString *qrCode))onSuccess;

@end
