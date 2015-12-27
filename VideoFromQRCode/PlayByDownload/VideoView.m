//
//  VideoView.m
//  CustomPlayer
//
//  Created by  江志磊 on 14-7-3.
//  Copyright (c) 2014年  江 志磊. All rights reserved.
//

#import "VideoView.h"

@implementation VideoView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}


//调用self.layer 会自动触发此方法，重写此方法，保证给到view的是AVPlayerLayer,而不是普通的CALayer
+(Class)layerClass{
    return [AVPlayerLayer class];
}
//将视频播放器，传给View
- (void)setVideoViewWithPlayer:(AVPlayer *)player{
    //AVPlayerLayer 视频播放器进行视频播放对应的层
    AVPlayerLayer *playerLayer = (AVPlayerLayer *)self.layer;
    //将播放器赋值给层，视频播放的画面会通过播放器渲染到view的层上
    [playerLayer setPlayer:player];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
