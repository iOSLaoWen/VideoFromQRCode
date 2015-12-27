//
//  LWHttpConnection.m
//  VideoFromQRCode
//
//  Created by LaoWen on 15/12/24.
//  Copyright © 2015年 LaoWen. All rights reserved.
//

#import "LWHttpConnection.h"

@interface LWMultipartFormData ()

@property (nonatomic, copy)NSString *boundary2;

@end

@implementation LWMultipartFormData
{
    NSMutableData *_data;
}

- (id)init
{
    if (self = [super init]) {
        _data = [[NSMutableData alloc]init];
    }
    return self;
}

- (void)appendPartWithFileData:(NSData *)data
                          name:(NSString *)name
                      fileName:(NSString *)fileName
                      mimeType:(NSString *)mimeType
{
    //拼接要上传的数据，格式如下：
    //--分隔符\r\n
    //Content-Disposition: form-data; name="name"; filename="filename"\r\n
    //Content-Type: mime类型\r\n
    //\r\n
    //要上传的数据
    //\r\n
    
    [_data appendData:[self.boundary2 dataUsingEncoding:NSUTF8StringEncoding]];
    [_data appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", name, fileName]dataUsingEncoding:NSUTF8StringEncoding]];
    [_data appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n\r\n", mimeType] dataUsingEncoding:NSUTF8StringEncoding]];//Content-Type后有一个空行
    [_data appendData:data];
    [_data appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
}

- (NSData *)data
{
    return _data;
}

@end

@interface LWHttpConnection ()<NSURLSessionDataDelegate>

@end

@implementation LWHttpConnection
{
    NSFileHandle *_fileHandle;
    NSURLSessionDataTask *_downloadTask;
    unsigned long long _sizeDownloaded;
    NSCondition *_condition;
    BOOL _done;
}

+ (LWHttpConnection *)GET:(NSString *)URLString
    success:(void (^)(LWHttpConnection *http, NSData *data))success
    failure:(void (^)(LWHttpConnection *http, NSError *error))failure
{
    LWHttpConnection *lwHttpConnection = [[LWHttpConnection alloc]init];
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithURL:[NSURL URLWithString:URLString] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            if (failure) {
                //TODO:在GET方法所在的线程中执行failure
                dispatch_async(dispatch_get_main_queue(), ^{
                    failure(lwHttpConnection, error);
                });
            }
        } else {
            if (success) {
                //TODO:在GET方法所在的线程中执行success
                dispatch_async(dispatch_get_main_queue(), ^{
                    success(lwHttpConnection, data);
                });
            }
        }
    }];
    [task resume];
    return lwHttpConnection;
}

+ (LWHttpConnection *)POST:(NSString *)URLString
    parameters:(NSDictionary *)parameters
       success:(void (^)(LWHttpConnection *http, NSData *data))success
       failure:(void (^)(LWHttpConnection *http, NSError *error))failure
{
    //把参数parameters转为name1=value1&name2=value2形式
    NSMutableString *strBody = [NSMutableString string];
    for (NSString *key in parameters) {
        [strBody appendFormat:@"%@=%@&", key, parameters[key]];
    }
    
    //去掉最后边的&
    if (strBody.length > 0) {
        [strBody deleteCharactersInRange:NSMakeRange(strBody.length-1, 1)];
    }
    
    NSData *body = [strBody dataUsingEncoding:NSUTF8StringEncoding];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:URLString]];
    [request setHTTPBody:body];
    
    //设置请求体长度
    [request addValue:[NSString stringWithFormat:@"%ld", body.length] forHTTPHeaderField:@"Content-Length"];
    
    [request setHTTPMethod:@"POST"];//设置请求类型为Post

    //设置Post类型为application/x-www-form-urlencoded
    [request addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    
    LWHttpConnection *lwHttpConnection = [[LWHttpConnection alloc]init];
    //建立http连接
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            if (failure) {
                //TODO:在GET方法所在的线程中执行failure
                dispatch_async(dispatch_get_main_queue(), ^{
                    failure(lwHttpConnection, error);
                });
            }
        } else {
            if (success) {
                //TODO:在GET方法所在的线程中执行success
                dispatch_async(dispatch_get_main_queue(), ^{
                    success(lwHttpConnection, data);
                });
            }
        }
    }];
    [task resume];
    return lwHttpConnection;
}

//Post请求，multipart/form-data类型
//URLString:网址
//parameters:组成query的键值对
//dataToUpload:要上传的数据
+ (LWHttpConnection *)POST:(NSString *)URLString
                parameters:(NSDictionary *)parameters
 constructingBodyWithBlock:(void (^)(LWMultipartFormData *formData))block
                   success:(void (^)(LWHttpConnection *http, NSData *data))success
                   failure:(void (^)(LWHttpConnection *http, NSError *error))failure
{
    LWHttpConnection *lwHttpConnection = [[LWHttpConnection alloc]init];
    
    NSString *boundary = [self generateBoundary];
    NSString *boundary2 = [NSString stringWithFormat:@"--%@\r\n", boundary];
    NSString *boundary3 = [NSString stringWithFormat:@"--%@--", boundary];
    
    NSMutableData *body = [NSMutableData data];
    
    //拼接传parameters中的各个参数，格式为：
    //--分隔符\r\n
    //Content-Disposition: form-data; name="参数名"\r\n
    //\r\n
    //参数值\r\n
    for (NSString *key in parameters) {
        [body appendData:[boundary2 dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n%@\r\n", key, parameters[key]]dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    //构建要上传的数据
    if (block) {
        LWMultipartFormData *formData = [[LWMultipartFormData alloc]init];
        formData.boundary2 = boundary2;
        block(formData);
        [body appendData:formData.data];
    }
    
    [body appendData:[boundary3 dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:URLString]];
    [request setHTTPMethod:@"POST"];
    [request setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary] forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%ld", body.length] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:body];
    
    NSURLSession *session = [NSURLSession sharedSession];

    NSURLSessionUploadTask *task = [session uploadTaskWithRequest:request fromData:body completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            if (failure) {
                //TODO:在GET方法所在的线程中执行failure
                dispatch_async(dispatch_get_main_queue(), ^{
                    failure(lwHttpConnection, error);
                });
            }
        } else {
            if (success) {
                //TODO:在GET方法所在的线程中执行success
                dispatch_async(dispatch_get_main_queue(), ^{
                    success(lwHttpConnection, data);
                });
            }
        }
    }];
    [task resume];
    
    return lwHttpConnection;
}

//产生一个LW开头+30位随机数的字符串做为boundary
+ (NSString *)generateBoundary
{
    NSMutableString *boundary = [NSMutableString stringWithString:@"LW"];
    for (NSUInteger i=0; i<10; i++) {
        NSUInteger num = arc4random()%10000;
        [boundary appendString:[NSString stringWithFormat:@"%lu", num]];
    }
    return boundary;
}

//下载文件,如果文件不存在就下载，如果存在就续传
//使用限制：如果文件下载一部分暂停，续传之前服务器上的文件发生变化可能会出错。
//TODO:异步下载完成时做回调
+ (LWHttpConnection *)download:(NSString *)URLString
                        toPath:(NSString *)path
                       success:(void (^)(LWHttpConnection *http, NSString *URLString))success
                       failure:(void (^)(LWHttpConnection *http, NSError *error))failure waitUntilDone:(BOOL)waitUntilDone
{
    LWHttpConnection *lwHttpConnection = [[LWHttpConnection alloc]init];
    if (waitUntilDone) {
        lwHttpConnection->_condition = [[NSCondition alloc]init];
        lwHttpConnection->_done = NO;
    }
    
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:path]) {
        [fm createFileAtPath:path contents:nil attributes:nil];
    }
    
    lwHttpConnection->_fileHandle = [NSFileHandle fileHandleForWritingAtPath:path];
    [lwHttpConnection->_fileHandle seekToEndOfFile];//移到文件尾
    lwHttpConnection->_sizeDownloaded = [lwHttpConnection->_fileHandle offsetInFile];
    
    NSURL *url = [NSURL URLWithString:URLString];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc]initWithURL:url];
    NSString *strRange = [NSString stringWithFormat:@"bytes=%lld-", lwHttpConnection->_sizeDownloaded];
    [request addValue:strRange forHTTPHeaderField:@"Range"];

    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:lwHttpConnection delegateQueue:nil];//[NSOperationQueue mainQueue]];
    lwHttpConnection->_downloadTask = [session dataTaskWithRequest:request];

    [lwHttpConnection->_downloadTask resume];
    
    if (waitUntilDone) {//等待下载完成
        [lwHttpConnection->_condition lock];
        while (!lwHttpConnection->_done) {
            [lwHttpConnection->_condition wait];
        }
        [lwHttpConnection->_condition unlock];
    }
    return lwHttpConnection;
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    NSHTTPURLResponse *response = (NSHTTPURLResponse*)dataTask.response;
    if (response.statusCode>=200 && response.statusCode<300) {
        [_fileHandle writeData:data];
        unsigned long long contentLength = [response.allHeaderFields[@"Content-Length"] longLongValue];
        _sizeDownloaded += data.length;
        if (_sizeDownloaded == contentLength) {
            [_fileHandle closeFile];
            if (_condition) {//下载完成发信号
                [_condition lock];
                _done = YES;
                [_condition signal];
                [_condition unlock];
            }
        }
    }
}

- (void)pause
{
    [_downloadTask cancel];
    [_fileHandle closeFile];
}

@end
