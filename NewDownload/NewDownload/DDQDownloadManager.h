//
//  DDQDownloadManager.h
//  NewDownload
//
//  Created by 123 on 2017/6/2.
//  Copyright © 2017年 DDQ. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "DDQDownloadFileManager.h"
#import "DDQDownloadOperation.h"

typedef NS_ENUM(NSUInteger, DDQDownloadManagerStates) {
    
    kManagerStart,
    kManagerSupsend,
    kManagerCancel,
};

typedef void(^DDQDownloadError)(NSError *error);
typedef void(^DDQDownloadSpeed)(float speed);
/**
 下载器
 */
@interface DDQDownloadManager : NSObject<NSURLSessionDataDelegate>

/**
 初始化方法

 @return 一个本类的实例
 */
+ (instancetype)downloadManager;

/**
 开启一个任务

 @param url 任务地址
 @param schedule 任务当前进度
 @param state 任务下载状态
 @param failure 网络原因造成的失败
 */
- (void)manager_downloadWithURL:(NSString *)url Schedule:(DDQDownloadSchedule)schedule State:(void (^)(DDQDownloadStates state))state Failure:(void(^)(NSError *downloadError))failure;

/**
 处理当前任务的状态
 
 @param state 任务处于什么状态
 @param url 任务的地址
 */
- (void)manager_handleTaskWithState:(DDQDownloadManagerStates)state URL:(NSString *)url;

/**
 任务是否下载完成

 @param url 下载任务的url
 @return 下载完成的状态
 */
- (BOOL)manager_downloadTaskCompletedWithURL:(NSString *)url;

/**
 这个任务下载的完成比例

 @param url 任务的URL
 @return 完成的百分比
 */
- (float)manager_downloadTaskRateWithURL:(NSString *)url;

/**
 任务的下载速率

 @param url 任务的URL
 @param speed 下载的速率
 */
- (void)manager_downloadSpeedWithURL:(NSString *)url Speed:(DDQDownloadSpeed)speed;

@end
