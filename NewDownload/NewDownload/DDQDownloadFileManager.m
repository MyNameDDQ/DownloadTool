//
//  DDQDownloadFileManager.m
//  NewDownload
//
//  Created by 123 on 2017/6/2.
//  Copyright © 2017年 DDQ. All rights reserved.
//

#import "DDQDownloadFileManager.h"
#import <UIKit/UIApplication.h>

typedef NS_ENUM(NSUInteger, ManagerOperationType) {
    kGetFileName,
    kGetFilePath,
};

@interface DDQDownloadFileManager ()

@end

@implementation DDQDownloadFileManager

+ (void)load {

    NSString *cachePath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).lastObject;
    NSString *savePath = [cachePath stringByAppendingPathComponent:@"DownloadFile"];
    
    fileManager = [NSFileManager defaultManager];
    //判断存储文件是否存在
    if (![fileManager fileExistsAtPath:savePath]) {
        
        [fileManager createDirectoryAtPath:savePath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    downloadSavePath = savePath;
    
    //缓存任务内容
    downloadTaskDic = [NSMutableDictionary dictionary];

    //任务的一些网络数据
    downloadDataPath = [NSString stringWithFormat:@"%@/DownloadData.plist", cachePath];
    NSMutableDictionary *dataDic = [NSMutableDictionary dictionaryWithContentsOfFile:downloadDataPath];
    //读取的plist文件不为空
    if (!dataDic) {
        
        dataDic = [NSMutableDictionary dictionary];
        [dataDic writeToFile:downloadDataPath atomically:YES];
    }
    
    //任务的一些网络数据
    downloadNamePath = [NSString stringWithFormat:@"%@/DownloadTaskName.plist", cachePath];
    NSMutableDictionary *nameDic = [NSMutableDictionary dictionaryWithContentsOfFile:downloadNamePath];
    //读取的plist文件不为空
    if (!nameDic) {
        
        nameDic = [NSMutableDictionary dictionary];
        [nameDic writeToFile:downloadNamePath atomically:YES];
    }
}

static NSString *downloadSavePath = nil;//文件保存文件
static NSString *downloadDataPath = nil;//下载的数据plist
static NSString *downloadNamePath = nil;//文件展示给用户看的时候显示正确的名字
static NSMutableDictionary *downloadTaskDic = nil;
static NSFileManager *fileManager = nil;

NSString *const ManagerFileSavePath = @"fileManager.savePath";
DDQFileManagerDataKey const DDQFileManagerTaskSizeKey = @"manager.fileSize";
DDQFileManagerDataKey const DDQFileManagerTaskNameKey = @"manager.fileName";

static DDQDownloadFileManager *manager = nil;
+ (instancetype)defaultFileManager {

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        manager = [[self alloc] init];
    });
    return manager;
}

//- (instancetype)init {
//
//    self = [super init];
//    if (self) {
//     
//        //程序将要被kill
//        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillTerminateNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
//            
//            
//        }];
//        return self;
//    }
//    return nil;
//}

- (void)setTaskUrl:(NSString *)taskUrl {

    //以url的结尾为文件名作为key
    NSString *contentKey = taskUrl.lastPathComponent;
    
    //临时缓存中有无该url
    if (![downloadTaskDic.allKeys containsObject:taskUrl]) {
        
        [downloadTaskDic setValue:[self file_handleUrl:taskUrl] forKey:contentKey];
    }
}

- (NSString *)taskDataPlistPath {

    return downloadDataPath;
}

- (NSString *)taskNamePlistPath {
    
    return downloadNamePath;
}
/**
 根据Task url拼接文件保存路径

 @param url 任务地址
 @return 文件路径
 */
- (NSString *)file_handleUrl:(NSString *)url {

    return [downloadSavePath stringByAppendingPathComponent:url.lastPathComponent];
}

/**
 集中处理

 @param url 任务的url
 @param type 操作的类型
 @return 处理的结果
 */
- (NSString *)file_handleOperationUrl:(NSString *)url Type:(ManagerOperationType)type {

    NSString *content = nil;

    //查看缓存是否存在
    if ([downloadTaskDic.allKeys containsObject:url.lastPathComponent]) {
        
        switch (type) {
                
            case kGetFileName:{
                content = url.lastPathComponent;
            }break;
                
            case kGetFilePath:{
                content = downloadTaskDic[url.lastPathComponent];
            }break;
                
            default:
                break;
        }
        return content;
    }
    
    //本地文件是否存在
    NSString *taskSavePath = [self file_handleUrl:url];
    if ([fileManager fileExistsAtPath:taskSavePath]) {
        
        switch (type) {
                
            case kGetFileName:{
                content = taskSavePath.lastPathComponent;
            }break;
                
            case kGetFilePath:{
                content = taskSavePath;
            }break;
                
            default:
                break;
        }
    }
    return content;
}

#pragma mark - API IMP
- (NSString *)file_getTaskFileNameWithUrl:(NSString *)url {

    return [self file_handleOperationUrl:url Type:kGetFileName];
}

- (NSString *)file_getTaskFilePathWithUrl:(NSString *)url {

    return [self file_handleOperationUrl:url Type:kGetFilePath];
}

- (NSUInteger)file_getTaskFileSizeWithUrl:(NSString *)url {

    NSString *savePath = [self file_getTaskFilePathWithUrl:url];
    //保存路径不为空，即为文件存在
    if (savePath) {
        
        NSDictionary *attrDic = [fileManager attributesOfItemAtPath:savePath error:nil];
        return [attrDic[NSFileSize] longValue];
    }
    
    return 0;
}

- (BOOL)file_deleteTaskFileWithUrl:(NSString *)url {

    NSString *path = [self file_getTaskFilePathWithUrl:url];
    
    //查看文件是否存在
    BOOL isOk = NO;
    if ([fileManager fileExistsAtPath:path]) {
        
        isOk = [fileManager removeItemAtPath:path error:nil];
        
        NSMutableDictionary *dataDic = [NSMutableDictionary dictionaryWithContentsOfFile:downloadDataPath];
        
        if ([dataDic.allKeys containsObject:url.lastPathComponent]) {
            
            [dataDic removeObjectForKey:url.lastPathComponent];
            [dataDic writeToFile:downloadDataPath atomically:YES];
        }
        return isOk;
    }
    return isOk;
}

@end
