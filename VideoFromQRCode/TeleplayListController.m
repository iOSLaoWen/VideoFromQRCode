//
//  TeleplayListController.m
//  VideoFromQRCode
//
//  Created by LaoWen on 15/12/23.
//  Copyright © 2015年 LaoWen. All rights reserved.
//

#import "TeleplayListController.h"
#import "TeleplayCollectionManager.h"
#import "TeleplayModel.h"
#import "TeleplayDetailController.h"
#import "LWQRCodeReadController.h"
#import "MBProgressHUDManager.h"
#import "LWHttpConnection.h"
#import "LWRSA.h"
#import "NSData+Base64.h"
#import "NSString+Hashing.h"
#import "RSAKeys.h"
#import "LWReachability.h"

//电视剧名列表页面
@implementation TeleplayListController
{
    NSMutableArray *_dataSource;
    MBProgressHUDManager *_hudManager;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self buildUI];
    [self prepareData];
    [self showData];
}

- (void)buildUI
{
    _hudManager = [[MBProgressHUDManager alloc]initWithView:self.view];
    
    //国际化
    NSString *title = NSLocalizedStringFromTable(@"Scan", @"InfoPlist", nil);
    [self.btnScanQRCode setTitle:title forState:UIControlStateNormal];
}

//从二维码包含的信息中验证并提取有效url
- (NSString *)verifyAndExtractUrl:(NSString *)strUrl;
{
    //二维码中包含的url结构为: 原始url#base64编码的数字签名
    //数字签名方案为：原始url的MD5值做RSA私钥加密
    
    //拆出原始url和签名
    NSRange range = [strUrl rangeOfString:@"#" options:NSBackwardsSearch];
    if (range.location == NSNotFound) {//未找到#,二维码非法
        return nil;
    }
    NSString *strOriginalUrl = [strUrl substringToIndex:range.location];//原始URL
    NSString *base64Signature = [strUrl substringFromIndex:range.location+range.length];//base64编码的数字签名
    NSLog(@"base64Signature: %@", base64Signature);
    NSData *signature = [NSData dataFromBase64String:base64Signature];//base64解码，得到数字签名
    LWRSA *rsa = [[LWRSA alloc]init];
    [rsa setPublicKey:PUBLIC_KEY];//设置RSA公钥
    NSData *md5 = [rsa decryptDataWithPublicKey:signature];//对数字签名用RSA公钥解密得到原始url的md5值
    NSString *strMd5 = [[NSString alloc]initWithData:md5 encoding:NSUTF8StringEncoding];
    NSLog(@"md5: %@", strMd5);
    
    NSString *strMd51 = [strOriginalUrl MD5Hash];//计算原始url的md5
    NSLog(@"md51: %@", strMd51);
    if ([strMd5 isEqualToString:strMd51]) {//两个md5值一样，验证通过
        return strOriginalUrl;
    }
    
    return nil;
}

//从网址获取电视剧并添加到电视剧列表
- (void)cacheTeleplayFromURL:(NSString *)strUrl
{
    [_hudManager showMessage:@"玩命加载数据中..."];
    //请求二维码中给的网址
    [LWHttpConnection GET:strUrl success:^(LWHttpConnection *http, NSData *data) {
        //GET方法同部做了线程同步处理，本段代码是在主线程中执行的
        //取消菊花
        [_hudManager hide];
        //二维码给的网址对应一个json文件，里边存的是一部电视剧的信息
        //TODO:JSOnModel应该可以一步解决模型嵌套问题
        TeleplayModel *model = [[TeleplayModel alloc]initWithData:data error:nil];
        NSLog(@"model: %@", model);
        
        //将这部电视剧存入数据库
        [[TeleplayCollectionManager defaultManager]insertTeleplayWithTeleplayModel:model];
        [_dataSource addObject:model];
        [_tableView reloadData];
        //TODO:扫到二维码后直接跳到详情页面
    } failure:^(LWHttpConnection *http, NSError *error) {
        //网络不通
        if ([[LWReachability defaultReachability] isInternetReachable]) {
            [_hudManager showErrorWithMessage:@"您的网络不通\n请检查网络设置" duration:2];
        } else {
            [_hudManager showErrorWithMessage:@"连接服务器失败" duration:2];
        }
    }];
}

//扫二维码看电视剧
- (IBAction)onBtnReadQRCodeClicked:(id)sender {
    LWQRCodeReadController *qrCodeCtrl = [[LWQRCodeReadController alloc]initWithBlock:^(NSString *qrCode) {
        //LWQRCodeReadController内部已经做了线程处理，本段代码是在主线程中执行的。
        
        NSLog(@"二维码:%@", qrCode);
        NSString *strUrl = [self verifyAndExtractUrl:qrCode];
        if (!strUrl) {
            [_hudManager showErrorWithMessage:@"二维码非法" duration:2];
            return;
        }
        [self cacheTeleplayFromURL:strUrl];
    }];
    [self.navigationController pushViewController:qrCodeCtrl animated:YES];
}

//处理远程推送
- (void)onRemoteNotification:(NSDictionary *)info
{
    NSString *strUrl = info[@"url"];
    NSLog(@"onRemoteNotification: %@, thread:%@", strUrl, [NSThread currentThread]);
    if (!strUrl) {
        [_hudManager showErrorWithMessage:@"推送信息无效" duration:2];
    } else {
        [self cacheTeleplayFromURL:strUrl];
    }
}

- (void)prepareData
{
    //从数据获得电视剧名列表
    _dataSource = [[NSMutableArray alloc]init];
    [_dataSource addObjectsFromArray:[[TeleplayCollectionManager defaultManager]allTeleplays]];
}

- (void)showData
{
    _tableView.dataSource = self;
    _tableView.delegate = self;
    [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
    [_tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    TeleplayModel *model = _dataSource[indexPath.row];
    cell.textLabel.text = model.name;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    TeleplayDetailController *teleplayDetailCtrl = [sb instantiateViewControllerWithIdentifier:@"TeleplayDetailController"];
    TeleplayModel *model = _dataSource[indexPath.row];
    teleplayDetailCtrl.teleplayID = model.ID;//要看的电视剧ID
    [self.navigationController pushViewController:teleplayDetailCtrl animated:YES];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *delete = NSLocalizedStringFromTable(@"delete", @"InfoPlist", nil);
    return delete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    TeleplayModel *teleplay = _dataSource[indexPath.row];
    //删除数据库中的数据
    [[TeleplayCollectionManager defaultManager]deleteTeleplayWithID:teleplay.ID];
    [_dataSource removeObject:teleplay];
    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

@end
