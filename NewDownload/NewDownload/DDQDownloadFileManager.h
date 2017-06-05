//
//  DDQDownloadFileManager.h
//  NewDownload
//
//  Created by 123 on 2017/6/2.
//  Copyright © 2017年 DDQ. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NSString *DDQFileManagerDataKey;

/**
 这是下载路径的管理者,对下载文件进行统一管理
 */
@interface DDQDownloadFileManager : NSObject

/**
 初始化方法

 @return 一个本类的单例
 */
+ (instancetype)defaultFileManager;

/**
 任务URL
 */
@property (nonatomic, strong) NSString *taskUrl;

/**
 任务一些数据的保存
 */
@property (nonatomic, strong, readonly) NSString *taskDataPlistPath;

/**
 任务名字对应表
 */
@property (nonatomic, strong, readonly) NSString *taskNamePlistPath;

/**
 获取文件的保存名字

 @param url 任务的url
 @return 文件名称
 */
- (NSString *)file_getTaskFileNameWithUrl:(NSString *)url;

/**
 获取文件的保存路径

 @param url 任务的url
 @return 文件保存的路径
 */
- (NSString *)file_getTaskFilePathWithUrl:(NSString *)url;

/**
 获取文件的大小

 @param url 任务的url
 @return 文件当前的大小
 */
- (NSUInteger)file_getTaskFileSizeWithUrl:(NSString *)url;

/**
 删除对应的认为文件

 @param url 任务的url
 @return 删除结果
 */
- (BOOL)file_deleteTaskFileWithUrl:(NSString *)url;

@end

FOUNDATION_EXTERN DDQFileManagerDataKey const DDQFileManagerTaskSizeKey;
FOUNDATION_EXTERN DDQFileManagerDataKey const DDQFileManagerTaskNameKey;
