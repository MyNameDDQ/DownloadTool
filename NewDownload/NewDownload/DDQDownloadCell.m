//
//  DDQDonwloadCell.m
//  NewDownload
//
//  Created by 123 on 2017/6/2.
//  Copyright © 2017年 DDQ. All rights reserved.
//

#import "DDQDownloadCell.h"
#import "DDQDownloadFileManager.h"
#import "DDQDownloadManager.h"
@interface DDQDownloadCell ()

@property (nonatomic, strong) DDQDownloadFileManager *fileManager;
@property (strong, nonatomic) DDQDownloadManager *downloadManager;
@property (weak, nonatomic) IBOutlet UIProgressView *scheduleProgress;
@property (weak, nonatomic) IBOutlet UILabel *rateLabel;
@property (weak, nonatomic) IBOutlet UIButton *startButton;
@property (weak, nonatomic) IBOutlet UILabel *speedLabel;
@property (weak, nonatomic) IBOutlet UILabel *completedLabel;
@end

@implementation DDQDownloadCell

- (void)awakeFromNib {
    
    [super awakeFromNib];
    // Initialization code
    self.fileManager = [DDQDownloadFileManager defaultFileManager];
    self.downloadManager = [[DDQDownloadManager alloc] init];
}

- (void)setCell_taskUrl:(NSString *)cell_taskUrl {

    self.fileManager.taskUrl = cell_taskUrl;
    _cell_taskUrl = cell_taskUrl;
    float schedule = [self.downloadManager manager_downloadTaskRateWithURL:cell_taskUrl];
    [self.scheduleProgress setProgress:schedule animated:YES];
    self.rateLabel.text = [NSString stringWithFormat:@"%.f%%", schedule * 100.0];
    
    if (schedule == 1.0) {
        
        [self.startButton setTitle:@"完成" forState:UIControlStateNormal];
    }
}

#pragma mark - Cell Operation
- (IBAction)cell_taskStart:(UIButton *)sender {
    
    //下载地址不为空
    if (!self.cell_taskUrl || [self.cell_taskUrl isEqualToString:@""]) return;
    
    //按钮是否被点击过
    if (!sender.isSelected) {//第一次点击默认为NO
        
        [sender setTitle:@"暂停" forState:UIControlStateNormal];
        [sender setSelected:YES];
    } else {
    
        [sender setTitle:@"开始" forState:UIControlStateNormal];
        [sender setSelected:NO];
    }
    
    NSUInteger GBSize = 1024 * 1024 * 1024;
    [self.downloadManager manager_downloadWithURL:self.cell_taskUrl Schedule:^(NSUInteger receivedSize, NSUInteger expectedSize, float schedule) {
        
        [self.scheduleProgress setProgress:schedule animated:YES];
        self.rateLabel.text = [NSString stringWithFormat:@"%.f%%", schedule * 100.0];
        
        //判断这个下载的进度是否大于1GB
        NSString *expectedStr = nil;
        if (expectedSize < GBSize) {
            
            expectedStr = [NSString stringWithFormat:@"%.2fM", (expectedSize / 1024.0) / 1024.0];
        } else {
        
            expectedStr = [NSString stringWithFormat:@"%.2fG", (expectedSize / 1024.0) / 1024.0 / 1024.0];
        }
        
        NSString *receviedStr = nil;
        //下载的单位显示
        if (receivedSize < GBSize) {//这表示下载量小于1G
            
            receviedStr = [NSString stringWithFormat:@"%.2fM", (receivedSize / 1024.0) / 1024.0];
        } else {//这表示下载量大于1G
        
            receviedStr = [NSString stringWithFormat:@"%.2fG", (receivedSize / 1024.0) / 1024.0 / 1024.0];
        }
        
        self.completedLabel.text = [NSString stringWithFormat:@"%@/%@", receviedStr, expectedStr];

    } State:^(DDQDownloadStates state) {
        
        if (state == kDownloadCompleted) {
            
            [sender setTitle:@"完成" forState:UIControlStateNormal];
        }
        
    } Failure:^(NSError *downloadError) {
        
        NSLog(@"%@", downloadError);
    }];
    
    [self.downloadManager manager_downloadSpeedWithURL:self.cell_taskUrl Speed:^(float speed) {
        
        NSLog(@"%f", speed);
        self.speedLabel.text = [NSString stringWithFormat:@"%.1fM/s", speed];
    }];
}

- (IBAction)cell_taskDelete:(UIButton *)sender {
    
    if ([self.fileManager file_deleteTaskFileWithUrl:self.cell_taskUrl]) {
        
        self.rateLabel.text = @"0%";
        [self.scheduleProgress setProgress:0.0 animated:NO];
        [self.startButton setTitle:@"开始" forState:UIControlStateNormal];
        [self.startButton setSelected:NO];
        [self.downloadManager manager_handleTaskWithState:kManagerCancel URL:self.cell_taskUrl];
    }
}

@end
