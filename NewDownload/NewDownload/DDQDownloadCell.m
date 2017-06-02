//
//  DDQDonwloadCell.m
//  NewDownload
//
//  Created by 123 on 2017/6/2.
//  Copyright © 2017年 DDQ. All rights reserved.
//

#import "DDQDownloadCell.h"
#import "DDQDownloadFileManager.h"

@interface DDQDownloadCell ()

@property (nonatomic, strong) DDQDownloadFileManager *fileManager;

@end

@implementation DDQDownloadCell

- (void)awakeFromNib {
    
    [super awakeFromNib];
    // Initialization code
}

- (void)setCell_taskUrl:(NSString *)cell_taskUrl {

    self.fileManager = [DDQDownloadFileManager defaultFileManager];
    self.fileManager.taskUrl = cell_taskUrl;
}

- (IBAction)cell_taskStart:(UIButton *)sender {
    
}

- (IBAction)cell_taskDelete:(UIButton *)sender {
    
}

@end
