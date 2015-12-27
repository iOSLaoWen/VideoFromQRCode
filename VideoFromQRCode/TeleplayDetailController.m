//
//  TeleplayDetailController.m
//  VideoFromQRCode
//
//  Created by LaoWen on 15/12/23.
//  Copyright © 2015年 LaoWen. All rights reserved.
//

#import "TeleplayDetailController.h"
#import "TeleplayCollectionManager.h"
#import "TeleplayModel.h"
#import "VideoPlayController.h"

//电视剧详情页面
@implementation TeleplayDetailController
{
    NSArray *_dataSource;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self prepareData];
    [self showData];
}

- (void)prepareData
{
    _dataSource = [[TeleplayCollectionManager defaultManager]detailForTeleplayID:_teleplayID];
}

- (void)showData
{
    self.automaticallyAdjustsScrollViewInsets = NO;
    _tableView.dataSource = self;
    _tableView.delegate = self;
    [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"teleplayDetailCell"];
    [_tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"teleplayDetailCell"];
    TeleplaySectionModel *section = _dataSource[indexPath.row];
    cell.textLabel.text = section.name;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    VideoPlayController *videoPlayController = [storyboard instantiateViewControllerWithIdentifier:@"VideoPlayController"];
    TeleplaySectionModel *section = _dataSource[indexPath.row];
    videoPlayController.strUrl = section.url;
    [self presentViewController:videoPlayController animated:YES completion:nil];
}

@end
