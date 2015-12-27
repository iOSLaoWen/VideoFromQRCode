//
//  LWHttpConnection.h
//  VideoFromQRCode
//
//  Created by LaoWen on 15/12/24.
//  Copyright © 2015年 LaoWen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LWMultipartFormData : NSObject

- (void)appendPartWithFileData:(NSData *)data
                          name:(NSString *)name
                      fileName:(NSString *)fileName
                      mimeType:(NSString *)mimeType;

- (NSData *)data;

@end

@interface LWHttpConnection : NSObject

//Get请求
+ (LWHttpConnection *)GET:(NSString *)URLString
                        success:(void (^)(LWHttpConnection *http, NSData *data))success
    failure:(void (^)(LWHttpConnection *http, NSError *error))failure;

//Post请求，application/x-www-form-urlencoded类型
//URLString:网址
//parameters:组成query的键值对
+ (LWHttpConnection *)POST:(NSString *)URLString
                      parameters:(NSDictionary *)parameters
                         success:(void (^)(LWHttpConnection *http, NSData *data))success
       failure:(void (^)(LWHttpConnection *http, NSError *error))failure;

//Post请求，multipart/form-data类型
//URLString:网址
//parameters:组成query的键值对
+ (LWHttpConnection *)POST:(NSString *)URLString
                parameters:(NSDictionary *)parameters
constructingBodyWithBlock:(void (^)(LWMultipartFormData *formData))block
                   success:(void (^)(LWHttpConnection *http, NSData *data))success
                   failure:(void (^)(LWHttpConnection *http, NSError *error))failure;

//下载文件,如果文件不存在就下载，如果存在就续传
//使用限制：如果文件下载一部分暂停，续传之前服务器上的文件发生变化可能会出错。
+ (LWHttpConnection *)download:(NSString *)URLString
          toPath:(NSString *)path
         success:(void (^)(LWHttpConnection *http, NSString *URLString))success
         failure:(void (^)(LWHttpConnection *http, NSError *error))failure
                 waitUntilDone:(BOOL)waitUntilDone;

@end
