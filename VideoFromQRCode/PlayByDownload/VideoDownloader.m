//
//  VideoDownloader.m
//  PlayingByDownloading
//
//  Created by LaoWen on 15/12/6.
//  Copyright © 2015年 LaoWen. All rights reserved.
//

#import "NSString+Hashing.h"
#import "VideoDownloader.h"
#import "LocalVideoServer.h"
#import "NSString+Path.h"

@implementation VideoDownloader
{
    NSThread *_downloadThread;
    LocalVideoServer *_localVideoServer;
    //NSLock *_lock;
    NSCondition *_condition;
}

- (void)startWithStrUrl:(NSString *)strUrl
{
    //_lock = [[NSLock alloc]init];
    //启动下载m3u8及对应视频文件的线程
    _downloadThread = [[NSThread alloc]initWithTarget:self selector:@selector(downloadFunc:) object:strUrl];
    [_downloadThread start];
}

//获取本地视频缓存目录
- (NSString *)localVideoCacheDir
{
    return [NSString stringWithFormat:@"%@/Documents/VideoCache", NSHomeDirectory()];
}

//m3u8在本地服务器上的网址
- (NSString *)m3u8LocalUrl:(NSString *)strUrl
{
    NSRange rangeSlash = [strUrl rangeOfString:@"/" options:NSBackwardsSearch];
    return [NSString stringWithFormat:@"http://127.0.0.1:8080/%@/%@", [strUrl MD5Hash], [strUrl substringFromIndex:rangeSlash.location+rangeSlash.length]];
}

//获取m3u8文件对应的本地缓存目录
- (NSString *)m3u8LocalPath:(NSString *)strUrl
{
    //用m3u8文件网址的MD5值做为该文件及相应视频文件的文件夹
    NSString *localPath = [NSString stringWithFormat:@"%@/%@", [self localVideoCacheDir], [strUrl MD5Hash]];
    return localPath;
}

//获取m3u8文件对应的本地文件名
- (NSString *)m3u8LocalFile:(NSString *)strUrl
{
    NSRange rangeSlash = [strUrl rangeOfString:@"/" options:NSBackwardsSearch];
    NSString *m3u8Name = [strUrl substringFromIndex:rangeSlash.location+rangeSlash.length];
    return [NSString stringWithFormat:@"%@/%@", [self m3u8LocalPath:strUrl], m3u8Name];
}

//下载m3u8及其相关的视频文件到沙盒里
- (void)downloadFunc:(NSString *)strUrl
{
    if (_localVideoServer) {
        _localVideoServer = nil;
    }
    _localVideoServer = [[LocalVideoServer alloc]init];
    _localVideoServer.port = 8080;
    _localVideoServer.rootDir = [self localVideoCacheDir];
    //_localVideoServer.lock = _lock;
    _condition = [[NSCondition alloc]init];
    _localVideoServer.condition = _condition;
    [_localVideoServer start];
    
    //要播放的m3u8文件及对应的视频文件都缓存在本地的某个目录里，如果这个目录不存在就先创建。
    NSString *m3u8LocalPath = [self m3u8LocalPath:strUrl];
    if (![[NSFileManager defaultManager] fileExistsAtPath:m3u8LocalPath]) {
        [[NSFileManager defaultManager]createDirectoryAtPath:m3u8LocalPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    //得到m3u8的本地缓存路径
    NSString *m3u8LocalFile = [self m3u8LocalFile:strUrl];
    //得到m3u8视频文件下载状态的文件完整路径
    NSString *videoFilesStatusesFile = [NSString stringWithFormat:@"%@.plist", m3u8LocalFile];
    if (![[NSFileManager defaultManager] fileExistsAtPath:m3u8LocalFile]) {
        //m3u8文件还没有下载下来，我们将其下载不来
        NSURL *url = [NSURL URLWithString:strUrl];
        NSData *data = [NSData dataWithContentsOfURL:url];
        NSString *content = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
        
        NSMutableArray *videoFilesStatuses = [NSMutableArray array];//这个m3u8相关的视频文件的下载状态
        //m3u8文件是一个文本文件，拆分出其每行文本
        NSArray *lines = [content componentsSeparatedByString:@"\n"];
        //生成m3u8中的视频的下载状态文件
        for (NSString *line in lines) {
            if (![line hasPrefix:@"#"] && line.length>0) {
                //不以#开头的行应该是视频文件名
                //标记这个文件为未下载状态
                [videoFilesStatuses addObject:@{line: @0}];
            }
        }
        
        //[_lock lock];
        //保存下载状态文件
        [videoFilesStatuses writeToFile:videoFilesStatusesFile atomically:YES];
        //保存m3u8文件
        [data writeToFile:m3u8LocalFile atomically:YES];
        //[_lock unlock];
    }
    
    //读取下载状态
    NSMutableArray *videoFilesStatuses = [NSArray arrayWithContentsOfFile:videoFilesStatusesFile].mutableCopy;
    
    [_condition lock];
    _localVideoServer.videoFilesStatus = videoFilesStatuses;
    NSLog(@"signal videoFilesStatuses: %@", _condition);
    //发出信号通知LocalVideoServer下载状态文件已经生成
    [_condition signal];
    [_condition unlock];
    
    //遍历各视频文件的下载状态，每个下载状态是个字典，键名为视频文件名，键值为该视频文件的下载状态
    for (int i=0; i<videoFilesStatuses.count; i++) {
        NSDictionary *downloadStatus = videoFilesStatuses[i];
        NSRange rangeSlash = [strUrl rangeOfString:@"/" options:NSBackwardsSearch];
        if (rangeSlash.location != NSNotFound) {
            NSString *strFolder = [strUrl substringToIndex:rangeSlash.location];
            //要下载的视频文件名，仅文件名
            NSString *videoFileName = downloadStatus.allKeys[0];
            NSNumber *videoFileStatus = downloadStatus[videoFileName];
            //得到视频文件的完整（原始）网址
            NSString *strVideoUrl = [NSString stringWithFormat:@"%@/%@", strFolder, videoFileName];
            //NSLog(@"videoUrl: %@", strVideoUrl);
            //得到视频文件的本地完整路径
            NSString *localVideoFile = [NSString stringWithFormat:@"%@/%@", [self m3u8LocalPath:strUrl], videoFileName];
            
            //如果要m3u8对应的视频文件未下载，则下载
            if ([videoFileStatus isEqualToNumber:@0]) {
                //NSLog(@"localFile: %@", localVideoFile);
                NSData *videoData = [NSData dataWithContentsOfURL:[NSURL URLWithString:strVideoUrl]];
                
                [_condition lock];
                if (videoData) {
                    //[_lock lock];
                    [videoData writeToFile:localVideoFile atomically:YES];
                    //[_lock unlock];
                    videoFileStatus = @1;//标记为已下载
                } else {
                    videoFileStatus = @2;//标记为不存在（服务器上不存在该文件）
                }
                
                //更新下载状态
                [videoFilesStatuses replaceObjectAtIndex:i withObject:@{videoFileName: videoFileStatus}];
                [videoFilesStatuses writeToFile:videoFilesStatusesFile atomically:YES];
                
                //通知LocalVideoServer一个文件已经下载完成
                [_condition signal];
                [_condition unlock];
            }
        }
    }
    
    //NSLog(@"All video files downloaded");
}

@end
