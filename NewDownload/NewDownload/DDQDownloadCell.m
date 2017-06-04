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
@end

@implementation DDQDownloadCell

- (void)awakeFromNib {
    
    [super awakeFromNib];
    // Initialization code
    self.fileManager = [DDQDownloadFileManager defaultFileManager];
    self.downloadManager = [DDQDownloadManager defaultManager];
    
}

- (void)setCell_taskUrl:(NSString *)cell_taskUrl {

    self.fileManager.taskUrl = cell_taskUrl;
    _cell_taskUrl = cell_taskUrl;
    float schedule = [self.downloadManager manager_downloadTaskRateWithURL:cell_taskUrl];
    [self.scheduleProgress setProgress:schedule animated:YES];
    self.rateLabel.text = [NSString stringWithFormat:@"%.f%%", schedule * 100.0];
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
    
    [self.downloadManager manager_downloadWithURL:self.cell_taskUrl Schedule:^(NSUInteger receivedSize, NSUInteger expectedSize, float schedule) {
        
        [self.scheduleProgress setProgress:schedule animated:YES];
        self.rateLabel.text = [NSString stringWithFormat:@"%.f%%", schedule * 100.0];
        
    } State:^(DDQDownloadStates state) {
        
        if (state == kDownloadCompleted) {
            
            [sender setTitle:@"完成" forState:UIControlStateNormal];
            [sender setEnabled:NO];
        }
        
    } Failure:^(NSError *downloadError) {
        
        NSLog(@"%@", downloadError);
    }];
}

- (IBAction)cell_taskDelete:(UIButton *)sender {
    
    
    
}

@end
