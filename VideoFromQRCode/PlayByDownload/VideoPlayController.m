//
//  VideoPlayController.m
//  PlayingByDownloading
//
//  Created by LaoWen on 15/12/3.
//  Copyright © 2015年 LaoWen. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "VideoPlayController.h"
#import "VideoView.h"
#import "NSString+Hashing.h"
#import "VideoDownloader.h"
#import "LWReachability.h"
#import "MBProgressHUDManager.h"


@interface VideoPlayController ()
@property (weak, nonatomic) IBOutlet VideoView *videoView;

@property (weak, nonatomic) IBOutlet UISlider *progressSlider;

@end

@implementation VideoPlayController
{
    AVPlayer *_player; //视频播放器
    VideoDownloader *_downloader;
    MBProgressHUDManager *_hudManager;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    //TODO:进一步封装MBProgressHUDManager,不用每个页面都创建
    _hudManager = [[MBProgressHUDManager alloc]initWithView:self.view];
    
    [[LWReachability defaultReachability]addObserver:self selector:@selector(reachabilityChanged)];
    
    [self playVideoWithURL:self.strUrl];
}

- (void)reachabilityChanged
{
    if (![[LWReachability defaultReachability] isInternetReachable]) {
        NSLog(@"网络不通");
        [_hudManager showErrorWithMessage:@"网络不通，请检查您的网络设置" duration:2];
    }
}

- (void)playVideoWithURL:(NSString *)strUrl
{
    if (_downloader) {
        _downloader = nil;
    }
    _downloader = [[VideoDownloader alloc]init];
    [_downloader startWithStrUrl:strUrl];
    
    //获取要播放的m3u8文件在本地Server中的网址
    NSString *strLocalUrl = [_downloader m3u8LocalUrl:strUrl];
    NSURL *url = [NSURL URLWithString:strLocalUrl];
    if (_player) {
        [_player play];//暂停时调play方法，会继续播放视频,如果播放器处于播放状态，调用play方法，无效果
        return;
    }
    
    //AVAsset 视频资源的集合类，能够收集视频资源的信息(视频的类型、总时长等),还能对视频进行预加载处理
    AVAsset *aset = [AVAsset assetWithURL:url];
    //aset对象，通过此方法，根据tracks关键字来收集视频资源的信息,操作为异步的
    [aset loadValuesAsynchronouslyForKeys:[NSArray arrayWithObject:@"tracks"] completionHandler:^{
        //获取到视频预加载的状态
        AVKeyValueStatus status = [aset statusOfValueForKey:@"tracks" error:nil];
        //视频预加载完毕，收集信息成功
        if (status == AVKeyValueStatusLoaded) {
            //进行后续处理
            //创建视频对应的Item，将视频信息，通过asset对象传给Item
            AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:aset];
            //创建视频播放器,视频播放器，可以通过Item，来获取到视频的总时间和当前播放的时间
            _player = [[AVPlayer alloc] initWithPlayerItem:item];
            //将播放器赋值给VideoView
            [_videoView setVideoViewWithPlayer:_player];
            //播放视频
            [_player play];
            //通过视频播放器来获取播放进度
            //CMTime 视频的时间结构体,描述的是视频播放的帧数和帧率,CMTimeMake(1.0,1.0) 代表1秒
            //让视频播放器在主线程之外，每隔一秒，获取一次视频的状态
            //self->对block保持强引用，block通过_player对self也保持强引用(强-强引用)(self-block)
            //要想办法消除block对self的强引用
            __weak AVPlayer *weakPlayer = _player;
            __weak UISlider *weakSlider = _progressSlider;
            //用weak修饰的变量来指向_player,在block中,block不会通过weakPlayer对self保持强引用(block弱引用self)
            [_player addPeriodicTimeObserverForInterval:CMTimeMake(1.0,1.0) queue:dispatch_get_global_queue(0, 0) usingBlock:^(CMTime time) {
                //获取到当前的播放时间结构体CMTime
                CMTime current = weakPlayer.currentItem.currentTime;
                //获取总时间
                CMTime total = weakPlayer.currentItem.duration;
                //计算播放进度,需要把视频对应的时间结构体CMTime转化成秒数
                float progress =  CMTimeGetSeconds(current)/CMTimeGetSeconds(total);
                //回到主线程，刷新UI
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (progress>=0.0&&progress<=1.0) {
                        weakSlider.value = progress;
                    }
                });
            }];
        }
    }];
}

@end
