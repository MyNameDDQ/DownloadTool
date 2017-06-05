//
//  ViewController.m
//  NewDownload
//
//  Created by 123 on 2017/6/2.
//  Copyright © 2017年 DDQ. All rights reserved.
//

#import "ViewController.h"

#import "DDQDownloadCell.h"
#import "DDQDownloadFileManager.h"

#define kFirstVideoUrl @"http://120.25.226.186:32812/resources/videos/minion_01.mp4"
#define kSecondVideoUrl @"http://dlsw.baidu.com/sw-search-sp/soft/9d/25765/sogou_mac_32c_V3.2.0.1437101586.dmg"

#define kThirdVideoUrl @"http://app.qixingshidai.com/Public/Uploads/gh/2017-05-05/590c2f922b110.pdf"
#define kFourthVideoUrl @"http://app.qixingshidai.com/Public/Uploads/gh/2017-05-05/590c2ec7e6740.pdf"

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource, DDQDownloadCellDelegate, UIDocumentInteractionControllerDelegate>

@property (nonatomic, strong) NSArray *vc_sourceArray;

@property (weak, nonatomic) IBOutlet UITableView *vc_tableView;

@end

@implementation ViewController

NSString *const identifier = @"VCCellID";

- (void)viewDidLoad {
    
    [super viewDidLoad];

    //tableview config
    [self.vc_tableView registerNib:[UINib nibWithNibName:@"DDQDownloadCell" bundle:nil] forCellReuseIdentifier:identifier];
    
    //controller initialize
    self.vc_sourceArray = @[kFirstVideoUrl, kSecondVideoUrl, kThirdVideoUrl, kFourthVideoUrl];
}

#pragma mark - DataSource & Delegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    return self.vc_sourceArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    DDQDownloadCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
    
    cell.delegate = self;
    cell.cell_taskUrl = self.vc_sourceArray[indexPath.row];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {

    return 100.0;
}

#pragma mark - Custom Delegate
- (void)cell_selectedPreviewPDFWithCell:(DDQDownloadCell *)cell {

    NSURL *previewURL = [NSURL URLWithString:[NSString stringWithFormat:@"file://%@", cell.cell_taskLocalPath]];
    UIDocumentInteractionController *documentView = [UIDocumentInteractionController interactionControllerWithURL:previewURL];
    documentView.delegate = self;
    [documentView presentPreviewAnimated:YES];
}

- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller {

    return self;
}

@end
