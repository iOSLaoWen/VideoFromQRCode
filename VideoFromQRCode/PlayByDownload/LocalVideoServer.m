//
//  LocalVideoServer.m
//  PlayingByDownloading
//
//  Created by LaoWen on 15/12/3.
//  Copyright © 2015年 LaoWen. All rights reserved.
//

#import "LocalVideoServer.h"
#import "AsyncSocket.h"
#import "NSString+Path.h"

@interface LocalVideoServer () <AsyncSocketDelegate>

@end

@implementation LocalVideoServer
{
    AsyncSocket *_serverSocket;
    NSMutableArray *_sockets;//存放所有与客户连接通讯的Socket，以此对Socket强引用
    NSString *_path;
    NSFileHandle *_fileHandle;
    NSMutableData *_requestData;
    long long _rangeStart;
    long long _rangeEnd;
    long long _sizeUntransfered;//已发送的字节数
    NSThread *_thread;
}

- (void)threadFunc
{
    while (1) {
        [[NSRunLoop currentRunLoop]runUntilDate:[NSDate distantFuture]];
    }
}

- (BOOL)start
{
    _thread = [[NSThread alloc]initWithTarget:self selector:@selector(threadFunc) object:nil];
    [_thread start];
    [self performSelector:@selector(_start
                                    ) onThread:_thread withObject:nil waitUntilDone:YES];
    return YES;
}

- (BOOL)_start
{
    BOOL ret = YES;
    self.port = 8080;
    self.rootDir = [NSString stringWithFormat:@"%@/Documents/VideoCache", NSHomeDirectory()];
    _sockets = [[NSMutableArray alloc]init];
    
    //创建AsyncSocket
    _serverSocket = [[AsyncSocket alloc]initWithDelegate:self];
    
    //绑定端口、监听端口，接收来自客户端的连接请求
    NSError *error;
    if (![_serverSocket acceptOnPort:self.port error:&error]) {
        NSLog(@"acceptOnPort %ld fail: %@", self.port, error.localizedDescription);
        ret = NO;
    }
    
    NSLog(@"out thread block: %@", [NSThread currentThread]);
    return ret;
}

- (void)stop
{
    [self performSelector:@selector(_stop) onThread:_thread withObject:nil waitUntilDone:YES];
}

- (void)_stop
{
    if (_serverSocket) {
        [_serverSocket disconnect];
        _serverSocket = nil;
    }
}

- (void)dealloc
{
    [self stop];
}

//收到客户端发的连接请求并完成连接。
//参数一：先前创建的_serverSocket，也就是用于监听的Socket
//参数二：新连接的Socket，以后用此Socket与客户端通讯。必须对这个Socket做引用，否则会断开与客户端的连接。
- (void)onSocket:(AsyncSocket *)sock didAcceptNewSocket:(AsyncSocket *)newSocket
{
    [_sockets addObject:newSocket];//对newSocket强引用
    NSLog(@"didAcceptNewSocket: %@", [NSThread currentThread]);
    
    _requestData = [[NSMutableData alloc]init];
    
    //读出客户端发来的数据
    [newSocket readDataWithTimeout:-1 tag:100];
}

//参数一这个sock是与客户端通讯的那个Socket
- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    [self tryAnalysizeRequestData:data andSendResponseHeadOnSocket:sock];
    
    //读出客户端发来的数据
    [sock readDataWithTimeout:-1 tag:100];
}

- (void)onSocket:(AsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    NSLog(@"didWriteDataWithTag: %@", [NSThread currentThread]);
    [self sendDataOnSocket:sock];
}

//与客户端的连接正常断开
- (void)onSocketDidDisconnect:(AsyncSocket *)sock
{
    //解除对sock的强引用.
    [_sockets removeObject:sock];
}

//与客户端的连接即将出错断开
- (void)onSocket:(AsyncSocket *)sock willDisconnectWithError:(NSError *)err
{
    //解除对sock的强引用.
    [_sockets removeObject:sock];
}

- (void)tryAnalysizeRequestData:(NSData *)data andSendResponseHeadOnSocket:(AsyncSocket *)sock
{
    [_requestData appendData:data];
    NSString *strRequest = [[NSString alloc]initWithData:_requestData encoding:NSUTF8StringEncoding];
    NSRange rangeCRLF = [strRequest rangeOfString:@"\r\n\r\n"];
    if (rangeCRLF.location == NSNotFound) {
        return;
    }
    
    //已经得到完整的请求头
    NSLog(@"==========================");
    
    NSString *strRequestHead = [strRequest substringToIndex:rangeCRLF.location];
    NSArray *requestHeads = [strRequestHead componentsSeparatedByString:@"\r\n"];
    NSLog(@"receive request: %@", strRequestHead);
    
    //获取要访问的资源（文件）的路径
    NSString *resource = [requestHeads[0] componentsSeparatedByString:@" "][1];
    //转换为本地的绝对路径
    _path = [NSString stringWithFormat:@"%@%@", self.rootDir, resource];
    
    _rangeEnd = -1;
    _rangeStart = 0;
    
    //获取Range
    for (NSString *field in requestHeads) {
        NSRange rangeColon = [field rangeOfString:@"Range: bytes="];
        if (rangeColon.location != NSNotFound) {
            NSString *strRange = [field substringFromIndex:rangeColon.location + rangeColon.length];
            NSRange rangeMinus = [strRange rangeOfString:@"-"];
            _rangeStart = [strRange substringToIndex:rangeMinus.location].longLongValue;
            _rangeEnd = [strRange substringFromIndex:rangeMinus.location+rangeMinus.length].longLongValue;
            break;
        }
    }
    
    //这里有一个问题需要解决：我们是用一个本地的服务器对真正的流媒体（m3u8文件和相应的视频）文件做了一个中转，这样一来（视频）播放器从本地服务器下载数据的速度肯定远大于从原始服务器（m3u8和相应的视频文件原来所在的服务器），这就会产生一个问题，当播放器向本地服务器请求下载文件下这个文件可能还没有从原始服务器下载下来，这时需要等待从原始服务器把文件下载下来之后再响应。
    
    //等待下载状态文件生成完成
    [_condition lock];
    while (!_videoFilesStatus) {
        NSLog(@"wait _videoFilesStatus: %@", _condition);
        [_condition wait];
    }
    NSLog(@"_videoFilesStatus OK");
    [_condition unlock];
    
    do {
        [_condition lock];
        if ([[NSFileManager defaultManager]fileExistsAtPath:_path]) {
            NSLog(@"file :%@ exist", _path);
            [_condition unlock];
            break;
        } else {
            //等待文件VideoDownloader下载完成
            NSLog(@"file :%@ not exist, wait", _path);
            [_condition wait];
            
            NSString *fileName = [resource extractFileName];
            int status = -1;
            //找到要访问的文件的状态
            for (NSDictionary *dict in _videoFilesStatus) {
                if ([dict.allKeys[0] isEqualToString:fileName]) {
                    status = [dict.allValues[0] intValue];
                    break;
                }
            }
            [_condition unlock];
            if (status == 2 || status == -1) {//文件不存在
                break;
            }
        }
    }while (1);
    
    //发送响应头
    [self sendResponseHeadOnSock:sock];
}

- (void)sendResponseHeadOnSock:(AsyncSocket *)sock
{
    NSLog(@"send file:%@", [_path extractFileName]);
    long long fileSize = [[NSFileManager defaultManager]attributesOfItemAtPath:_path error:nil].fileSize;
    if (_rangeEnd == -1) {
        _rangeEnd = fileSize-1;
    }
    _sizeUntransfered = _rangeEnd-_rangeStart+1;
    _fileHandle = [NSFileHandle fileHandleForReadingAtPath:_path];
    [_fileHandle seekToFileOffset:_rangeStart];
    
    NSMutableString *responseHeader = [NSMutableString string];
    
    if (fileSize == 0) {//没找到文件
        [responseHeader appendString:@"HTTP/1.1 404 not found\r\n"];
    } else {
        if (fileSize == _rangeEnd-_rangeStart+1) {//客户端请求完整文件
            [responseHeader appendString:@"HTTP/1.1 200 OK\r\n"];
        } else {//客户端请求部分文件
            [responseHeader appendString:@"HTTP/1.1 206 Partial Content\r\n"];
        }
    }
    
    [responseHeader appendFormat:@"Content-Range: bytes %lld-%lld/%lld\r\n", _rangeStart, _rangeEnd, fileSize];
    [responseHeader appendFormat:@"Content-Length:%lld\r\n", _rangeEnd-_rangeStart+1];
    [responseHeader appendString:@"\r\n"];
    
    NSLog(@"responseHeader: %@", responseHeader);
    
    [sock writeData:[responseHeader dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:200];
}

//给客户端发送所请求的数据
- (void)sendDataOnSocket:(AsyncSocket *)sock
{
    if (_sizeUntransfered == 0) {
        [_fileHandle closeFile];
        [sock disconnect];//传输完服务器端必须主动关闭
        NSLog(@"transfer finisned");
        return;
    }
    
    long sizeToTransfer = (long)(_sizeUntransfered > 100*1024 ? 100*1024 : _sizeUntransfered);
    _sizeUntransfered -= sizeToTransfer;
    NSData *data = [_fileHandle readDataOfLength:sizeToTransfer];
    [sock writeData:data withTimeout:-1 tag:200];
}

@end
