//
//  DDQDonwloadCell.h
//  NewDownload
//
//  Created by 123 on 2017/6/2.
//  Copyright © 2017年 DDQ. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol DDQDownloadCellDelegate;

@interface DDQDownloadCell : UITableViewCell

@property (nonatomic, copy) NSString *cell_taskUrl;
@property (nonatomic, weak) id <DDQDownloadCellDelegate> delegate;
@property (nonatomic, strong, readonly) NSString *cell_taskLocalPath;

@end

@protocol DDQDownloadCellDelegate <NSObject>

@optional
- (void)cell_selectedPreviewPDFWithCell:(DDQDownloadCell *)cell;

@end

typedef NS_ENUM(NSUInteger, DownloadCellType) {
    
    kDownloadTypePDF,
    kDownloadTypeVideo,
    
};

@interface DDQDownloadCell (DDQDownloadCelltType)

@property (nonatomic, assign) DownloadCellType cell_type;

@end
