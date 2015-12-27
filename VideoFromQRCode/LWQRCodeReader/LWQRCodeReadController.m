//
//  LWQRCodeReadController.m
//  LWQRCodeReaderDemo
//
//  Created by LaoWen on 15/12/22.
//  Copyright © 2015年 LaoWen. All rights reserved.
//

#import "LWQRCodeReadController.h"
#import <AVFoundation/AVFoundation.h>
#import "ZBarReaderController.h"

@interface LWQRCodeReadController ()<AVCaptureMetadataOutputObjectsDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (strong, nonatomic) UIView *viewPreview;

@property (strong, nonatomic) UIView *boxView;
@property (nonatomic) BOOL isReading;
@property (strong, nonatomic) CALayer *scanLayer;

- (BOOL)startReading;
- (void)stopReading;

//捕捉会话
@property (nonatomic, strong) AVCaptureSession *captureSession;
//展示layer
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *videoPreviewLayer;
@end

@implementation LWQRCodeReadController

- (id)initWithBlock:(void(^)(NSString *qrCode))onSuccess
{
    self = [super init];
    self.onSuccess = onSuccess;
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    //self.view.backgroundColor = [UIColor whiteColor];
    
    _viewPreview = self.view;
#if TARGET_IPHONE_SIMULATOR
    //模拟器
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(onLongPress:)];
    [self.view addGestureRecognizer:longPress];
#else
    //真机
    [self startReading];
#endif
    [self buildUI];
}

- (void)buildUI
{
    //扫描框
    _boxView = [[UIView alloc] initWithFrame:CGRectMake(_viewPreview.bounds.size.width * 0.2f, _viewPreview.bounds.size.height * 0.2f, _viewPreview.bounds.size.width - _viewPreview.bounds.size.width * 0.4f, _viewPreview.bounds.size.height - _viewPreview.bounds.size.height * 0.4f)];
    _boxView.layer.borderColor = [UIColor greenColor].CGColor;
    _boxView.layer.borderWidth = 1.0f;
    
    [_viewPreview addSubview:_boxView];
    
    //扫描线
    _scanLayer = [[CALayer alloc] init];
    _scanLayer.frame = CGRectMake(0, 0, _boxView.bounds.size.width, 1);
    _scanLayer.backgroundColor = [UIColor brownColor].CGColor;
    
    [_boxView.layer addSublayer:_scanLayer];
    
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:0.2f target:self selector:@selector(moveScanLayer:) userInfo:nil repeats:YES];
    
    [timer fire];
    
    UILabel *label = [[UILabel alloc]initWithFrame:_boxView.bounds];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor whiteColor];
    [_boxView addSubview:label];
#if TARGET_IPHONE_SIMULATOR
    label.text = @"长按打开相册";
#else
    label.text = @"请把二维码置于框内";
#endif
}

- (BOOL)startReading {
    NSError *error;
    
    //1.初始化捕捉设备（AVCaptureDevice），类型为AVMediaTypeVideo
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    //2.用captureDevice创建输入流
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
    if (!input) {
        NSLog(@"%@", [error localizedDescription]);
        return NO;
    }
    
    //3.创建媒体数据输出流
    AVCaptureMetadataOutput *captureMetadataOutput = [[AVCaptureMetadataOutput alloc] init];
    
    //4.实例化捕捉会话
    _captureSession = [[AVCaptureSession alloc] init];
    
    //4.1.将输入流添加到会话
    [_captureSession addInput:input];
    
    //4.2.将媒体输出流添加到会话中
    [_captureSession addOutput:captureMetadataOutput];
    
    //5.创建串行队列，并加媒体输出流添加到队列当中
    dispatch_queue_t dispatchQueue;
    dispatchQueue = dispatch_queue_create("myQueue", NULL);
    //5.1.设置代理
    [captureMetadataOutput setMetadataObjectsDelegate:self queue:dispatchQueue];
    
    //5.2.设置输出媒体数据类型为QRCode
    [captureMetadataOutput setMetadataObjectTypes:[NSArray arrayWithObject:AVMetadataObjectTypeQRCode]];
    
    //6.实例化预览图层
    _videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
    
    //7.设置预览图层填充方式
    [_videoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    
    //8.设置图层的frame
    [_videoPreviewLayer setFrame:_viewPreview.layer.bounds];
    
    //9.将图层添加到预览view的图层上
    [_viewPreview.layer addSublayer:_videoPreviewLayer];
    
    //10.设置扫描范围
    captureMetadataOutput.rectOfInterest = CGRectMake(0.2f, 0.2f, 0.8f, 0.8f);
    
    //11.开始扫描
    [_captureSession startRunning];
    
    return YES;
}

-(void)stopReading{
    [_captureSession stopRunning];
    _captureSession = nil;
    [_scanLayer removeFromSuperlayer];
    [_videoPreviewLayer removeFromSuperlayer];
    
    [_scanLayer removeFromSuperlayer];
    _scanLayer = nil;
    [_boxView removeFromSuperview];
    _boxView = nil;
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    
    //判断是否有数据
    if (metadataObjects != nil && [metadataObjects count] > 0) {
        AVMetadataMachineReadableCodeObject *metadataObj = [metadataObjects objectAtIndex:0];
        //判断回传的数据类型
        if ([[metadataObj type] isEqualToString:AVMetadataObjectTypeQRCode]) {
            [self exitWithString:[metadataObj stringValue]];
        }
    }
}

- (void)moveScanLayer:(NSTimer *)timer
{
    static NSInteger direction = 1;//扫描线移动的方向
    CGFloat delta = _boxView.frame.size.width/5;//扫描线每次移动的距离
    CGRect frame = _scanLayer.frame;

    frame.origin.y += delta*direction;
    if (direction > 0 && _scanLayer.frame.origin.y >= _boxView.frame.size.height) {
        //向下移动时超出了最下边，改变方向
        direction = -direction;
        frame.origin.y = _boxView.frame.size.height*0.9;
    } else if (direction < 0 && _scanLayer.frame.origin.y <= 0)
    {
        //向上移动时超出了最上边，改变方向
        direction = -direction;
        frame.origin.y = _boxView.frame.size.height*0.1;
    }
    [UIView animateWithDuration:0.1 animations:^{
        _scanLayer.frame = frame;
    }];
}

//参数：带有二维码的图片
//返回值：二维码中的字符串
- (NSString *)stringFromQRCodeImage:(UIImage *)image
{
    ZBarReaderController *zbar = [[ZBarReaderController alloc]init];
    ZBarSymbol *symbol = nil;
    for (symbol in [zbar scanImage:image.CGImage]) {
        break;
    }
    if (symbol) {
        return symbol.data;
    }
    return nil;
}

- (void)onLongPress:(UILongPressGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateBegan) {
        UIImagePickerController *imagePicker = [[UIImagePickerController alloc]init];
        imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        imagePicker.allowsEditing = YES;
        imagePicker.delegate = self;
        [self presentViewController:imagePicker animated:YES completion:nil];
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    [picker dismissViewControllerAnimated:YES completion:^{
        UIImage *editedImage = info[UIImagePickerControllerEditedImage];
        NSString *str = [self stringFromQRCodeImage:editedImage];
        [self exitWithString:str];
    }];
}

//退出页面并回传扫到的二维码中的信息
- (void)exitWithString:(NSString *)strQrCode
{
    NSLog(@"current thread: %@", [NSThread currentThread]);
    [self stopReading];
    if ([[NSThread currentThread] isMainThread]) {
        if (self.navigationController) {
            [self.navigationController popViewControllerAnimated:YES];
        } else {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
        if (self.onSuccess) {
            self.onSuccess(strQrCode);
        }
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.navigationController) {
                [self.navigationController popViewControllerAnimated:YES];
            } else {
                [self dismissViewControllerAnimated:YES completion:nil];
            }
            if (self.onSuccess) {
                self.onSuccess(strQrCode);
            }
        });
    }
}

@end
