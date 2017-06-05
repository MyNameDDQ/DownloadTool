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
#import <objc/runtime.h>
@interface DDQDownloadCell ()

@property (nonatomic, strong) DDQDownloadFileManager *fileManager;
@property (strong, nonatomic) DDQDownloadManager *downloadManager;
@property (weak, nonatomic) IBOutlet UIProgressView *scheduleProgress;
@property (weak, nonatomic) IBOutlet UILabel *rateLabel;
@property (weak, nonatomic) IBOutlet UIButton *startButton;
@property (weak, nonatomic) IBOutlet UILabel *speedLabel;
@property (weak, nonatomic) IBOutlet UILabel *completedLabel;
@property (weak, nonatomic) IBOutlet UIButton *previewButton;
@end

@implementation DDQDownloadCell

- (void)awakeFromNib {
    
    [super awakeFromNib];
    // Initialization code
    self.fileManager = [DDQDownloadFileManager defaultFileManager];
    self.downloadManager = [DDQDownloadManager downloadManager];
    self.previewButton.hidden = YES;
}

- (void)setCell_taskUrl:(NSString *)cell_taskUrl {

    self.fileManager.taskUrl = cell_taskUrl;
    _cell_taskUrl = cell_taskUrl;
    float schedule = [self.downloadManager manager_downloadTaskRateWithURL:cell_taskUrl];
    [self.scheduleProgress setProgress:schedule animated:YES];
    self.rateLabel.text = [NSString stringWithFormat:@"%.f%%", schedule * 100.0];
    
    if (schedule == 1.0) {//下载比1，则下载完成
        
        [self.startButton setTitle:@"完成" forState:UIControlStateNormal];
    }
    
    //下载的文件类型为PDF，且下载完成
    if ([cell_taskUrl.pathExtension isEqualToString:@"pdf"] && schedule == 1.0) {
        
        self.previewButton.hidden = NO;
    }
    
    //监视下载速度
    [self.downloadManager manager_downloadSpeedWithURL:self.cell_taskUrl Speed:^(float speed) {
        
        self.speedLabel.text = [NSString stringWithFormat:@"%.1fM/s", speed];
    }];
}

- (void)setCell_name:(NSString *)cell_name {

    //建立名称关系
    NSMutableDictionary *nameDic = [NSMutableDictionary dictionaryWithContentsOfFile:self.fileManager.taskNamePlistPath];
    //记录已存在就不记录了
    if (![nameDic.allKeys containsObject:self.cell_taskUrl.lastPathComponent]) {
        
        [nameDic setValue:cell_name forKey:self.cell_taskUrl.lastPathComponent];
        [nameDic writeToFile:self.fileManager.taskNamePlistPath atomically:YES];
    }
}

- (NSString *)cell_taskLocalPath {

    return [NSString stringWithFormat:@"file://%@", [self.fileManager file_getTaskFilePathWithUrl:self.cell_taskUrl]];
}

- (NSString *)cell_taskLocalName {

    NSMutableDictionary *nameDic = [NSMutableDictionary dictionaryWithContentsOfFile:self.fileManager.taskNamePlistPath];
    //记录存在就读取记录
    if ([nameDic.allKeys containsObject:self.cell_taskUrl.lastPathComponent]) {
        
        return nameDic[self.cell_taskUrl.lastPathComponent];
    } else {
    
        return @"七星时代";
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
        
            expectedStr = [NSString stringWithFormat:@"%.2fG", 1.0 * expectedSize / GBSize];
        }
        
        NSString *receviedStr = nil;
        //下载的单位显示
        if (receivedSize < GBSize) {//这表示下载量小于1G
            
            receviedStr = [NSString stringWithFormat:@"%.2fM", (receivedSize / 1024.0) / 1024.0];
        } else {//这表示下载量大于1G
        
            receviedStr = [NSString stringWithFormat:@"%.2fG", 1.0 * receivedSize / GBSize];
        }
        
        self.completedLabel.text = [NSString stringWithFormat:@"%@/%@", receviedStr, expectedStr];

    } State:^(DDQDownloadStates state) {
        
        if (state == kDownloadCompleted) {
            
            [sender setTitle:@"完成" forState:UIControlStateNormal];
            
            //下载的是PDF
            if (self.cell_type == kDownloadTypePDF) {
                
                self.previewButton.hidden = NO;
            }
        }
        
    } Failure:^(NSError *downloadError) {
        
        NSLog(@"%@", downloadError);
    }];
    
}

- (IBAction)cell_taskDelete:(UIButton *)sender {
    
    //删除之间还是得判断文件是否存在
    if ([self.fileManager file_deleteTaskFileWithUrl:self.cell_taskUrl]) {
        
        self.rateLabel.text = @"0%";
        [self.scheduleProgress setProgress:0.0 animated:NO];
        [self.startButton setTitle:@"开始" forState:UIControlStateNormal];
        [self.startButton setSelected:NO];
        [self.downloadManager manager_handleTaskWithState:kManagerCancel URL:self.cell_taskUrl];
        self.speedLabel.text = @"0M/S";
        
        //下载的是PDF
        if (self.cell_type == kDownloadTypePDF) {
            
            self.previewButton.hidden = YES;
        }
    }
}

- (IBAction)cell_taskPreview:(UIButton *)sender {
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(cell_selectedPreviewPDFWithCell:)]) {
        
        [self.delegate cell_selectedPreviewPDFWithCell:self];
    }
}

@end

@implementation DDQDownloadCell (DDQDownloadCelltType)

@dynamic cell_type;

const char *typeKey = "com.ddq.cellType";

- (void)setCell_type:(DownloadCellType)cell_type {

    objc_setAssociatedObject(self, typeKey, @(cell_type), OBJC_ASSOCIATION_RETAIN);
}

- (DownloadCellType)cell_type {

    NSNumber *number = objc_getAssociatedObject(self, typeKey);
    if (!number) {
        
        return kDownloadTypeVideo;
    } else {
    
        return [number unsignedLongValue];
    }
}

@end
