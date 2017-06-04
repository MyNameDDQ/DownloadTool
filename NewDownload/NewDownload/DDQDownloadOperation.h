//
//  DDQDownloadOperation.h
//  NewDownload
//
//  Created by 123 on 2017/6/2.
//  Copyright © 2017年 DDQ. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, DDQDownloadStates) {
    
    kDownloadStart = 107038,
    kDownloadSupsend,
    kDownloadCompleted,
    kDownloadFailed,
    kDownloadCancel,
};

typedef void(^DDQDownloadSchedule)(NSUInteger receivedSize, NSUInteger expectedSize, float schedule);

typedef void(^DDQDownloadState)(DDQDownloadStates state);

/**
 下载实例操作
 */
@interface DDQDownloadOperation : NSObject

/**
 *  下载的地址
 */
@property (strong, nonatomic) NSString *download_address;

/**
 下载的session
 */
@property (nonatomic, strong) NSURLSessionDataTask *download_task;

/**
 *  输出流
 */
@property (strong, nonatomic) NSOutputStream *output_stream;

/**
 *  下载任务的总长度
 */
@property (assign, nonatomic) NSUInteger total_length;

/**
 *  下载进度的回调
 */
@property (copy, nonatomic) DDQDownloadSchedule download_schedule;

/**
 *  下载状态的回调
 */
@property (copy, nonatomic) DDQDownloadState download_state;

@end
