//
//  DDQDownloadManager.m
//  NewDownload
//
//  Created by 123 on 2017/6/2.
//  Copyright © 2017年 DDQ. All rights reserved.
//

#import "DDQDownloadManager.h"

@interface DDQDownloadManager ()

@property (nonatomic, strong) DDQDownloadFileManager *downloadFileManager;
@property (nonatomic, copy) DDQDownloadError downloadError;
@property (nonatomic, copy) DDQDownloadSpeed downloadSpeed;
@property (nonatomic, strong) dispatch_source_t timer_t;

@end

@implementation DDQDownloadManager

static NSMutableDictionary *managerTaskDic = nil;

+ (void)load {

    managerTaskDic = [NSMutableDictionary dictionary];
}

//static DDQDownloadManager *manager = nil;
//+ (instancetype)defaultManager {
//
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        manager = [[self alloc] init];
//    });
//    return manager;
//}

+ (instancetype)downloadManager {

    return [[self alloc] init];
}

- (instancetype)init {

    self = [super init];
    if (self) {
        
        self.downloadFileManager = [DDQDownloadFileManager defaultFileManager];
        self.timer_t = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
        return self;
    }
    return nil;
}

/**
 获得任务对应的大小

 @param url 任务的地址
 @return 任务的总大小
 */
- (NSUInteger)manager_downloadTaskTotalSizeWithURL:(NSString *)url {
    
    NSMutableDictionary *taskDataDic = [NSMutableDictionary dictionaryWithContentsOfFile:self.downloadFileManager.taskDataPlistPath];
    NSDictionary *dataDic = taskDataDic[url.lastPathComponent];
    return  [dataDic[DDQFileManagerTaskSizeKey] longValue];
}

/**
 url转当前任务

 @param url 待转换的url
 @return 当前任务
 */
- (DDQDownloadOperation *)manager_getURLLastPathComponent:(NSURL *)url {
    
    NSString *path = url.absoluteString;
    DDQDownloadOperation *operation = [managerTaskDic valueForKey:path.lastPathComponent];
    return operation;
}

#pragma mark - API IMP
- (void)manager_downloadWithURL:(NSString *)url Schedule:(DDQDownloadSchedule)schedule State:(void (^)(DDQDownloadStates))state Failure:(void (^)(NSError *))failure {

    //下载地址不为空，且不为NSNull，@""
    if (!url || [url isKindOfClass:[NSNull class]] || [url isEqualToString:@""]) return;
    
    //这个任务存在并且下载完成
    BOOL taskOK = [self manager_downloadTaskCompletedWithURL:url];
    if (taskOK) return;
    
    //当前是否有这个下载任务
    if ([managerTaskDic.allKeys containsObject:url.lastPathComponent]) {
        
        DDQDownloadOperation *operation = managerTaskDic[url.lastPathComponent];
        NSURLSessionDataTask *dataTask = operation.download_task;
        //根据当前任务状态做出判断
        if (dataTask.state == NSURLSessionTaskStateRunning) {
            
            [self manager_handleTaskWithState:kManagerSupsend URL:url]; return;
        } else if (dataTask.state == NSURLSessionTaskStateSuspended) {
            
            [self manager_handleTaskWithState:kManagerStart URL:url]; return;
        }
    }
    
    self.downloadFileManager.taskUrl = url;
    
    //创建流
    NSOutputStream *output_stream = [NSOutputStream outputStreamToFileAtPath:[self.downloadFileManager file_getTaskFilePathWithUrl:url] append:YES];
    
    //设置请求头
    NSMutableURLRequest *url_request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    url_request.timeoutInterval = 10.0;
    NSString *range = [NSString stringWithFormat:@"bytes=%zd-", [self.downloadFileManager file_getTaskFileSizeWithUrl:url]];
    [url_request setValue:range forHTTPHeaderField:@"Range"];
    
    //任务
    NSURLSession *default_session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    NSURLSessionDataTask *data_task = [default_session dataTaskWithRequest:url_request];
    [data_task resume];
    
    //不为空就提示开始运行啦
    if (!state) return;
    state(kDownloadStart);
    
    //任务操作类
    DDQDownloadOperation *operation = [[DDQDownloadOperation alloc] init];
    operation.download_address = [self.downloadFileManager file_getTaskFilePathWithUrl:url];
    operation.output_stream = output_stream;
    operation.download_schedule = schedule;
    operation.download_state = state;
    operation.download_task = data_task;
    
    [managerTaskDic setValue:operation forKey:url.lastPathComponent];
    
    //下载错误不为空
    if (failure) {
        
        self.downloadError = failure;
    }
}

- (BOOL)manager_downloadTaskCompletedWithURL:(NSString *)url {

    NSUInteger totalLength = [self manager_downloadTaskTotalSizeWithURL:url];//总下载量
    NSUInteger currentLength = [self.downloadFileManager file_getTaskFileSizeWithUrl:url];//已下载量
    
    //总下载量和当前下载量比对
    if (totalLength == currentLength && (totalLength > 0 && currentLength > 0)) {
        
        return YES;
    } else {
    
        return NO;
    }
}

- (void)manager_handleTaskWithState:(DDQDownloadManagerStates)state URL:(NSString *)url {

    DDQDownloadOperation *operation = [managerTaskDic valueForKey:url.lastPathComponent];
    NSURLSessionDataTask *dataTask = operation.download_task;
    //根据所需处理的状态进行处理
    switch (state) {
            
        case kManagerStart:{
            [dataTask resume];
            operation.download_state(kDownloadStart);
            dispatch_resume(self.timer_t);
        }break;
            
        case kManagerSupsend:{
            [dataTask suspend];
            operation.download_state(kDownloadSupsend);
            dispatch_suspend(self.timer_t);
        }break;
            
        case kManagerCancel:{
            [dataTask cancel];
//            operation.download_state(kDownloadCancel);
        }break;
            
        default:
            break;
    }
}

- (float)manager_downloadTaskRateWithURL:(NSString *)url {

    NSUInteger totalLength = [self manager_downloadTaskTotalSizeWithURL:url];//总下载量
    NSUInteger currentLength = [self.downloadFileManager file_getTaskFileSizeWithUrl:url];//已下载量
    
    //分子分母不为零
    if (totalLength == 0 || currentLength == 0) return 0.f;
    return 1.0 * currentLength / totalLength;
}

- (void)manager_downloadSpeedWithURL:(NSString *)url Speed:(void (^)(float))speed {

    __block NSUInteger lowLength = [self.downloadFileManager file_getTaskFileSizeWithUrl:url];//已下载量

    //没1秒读取新的文件打下，再与上一次记录的大小取差值
    dispatch_source_set_timer(self.timer_t, DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC, 0.0 * NSEC_PER_SEC);
    dispatch_source_set_event_handler(self.timer_t, ^{
        
        NSUInteger currentLength = [self.downloadFileManager file_getTaskFileSizeWithUrl:url];//已下载量
        
        if (!speed) return;//这个回调得不为空
        speed((currentLength - lowLength) / 1024.0 / 1024.0);
        
        lowLength = currentLength;
    });
    dispatch_resume(self.timer_t);
}

#pragma mark - Session Delgate
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSHTTPURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    
    DDQDownloadOperation *operation = [self manager_getURLLastPathComponent:dataTask.currentRequest.URL];

    //打开流
    [operation.output_stream open];
    
    //计算总长度
    NSUInteger response_length = [response.allHeaderFields[@"Content-Length"] integerValue] + [self.downloadFileManager file_getTaskFileSizeWithUrl:operation.download_address.lastPathComponent];
    operation.total_length = response_length;
    
    //将数据写入文件
    NSMutableDictionary *data_dic = [NSMutableDictionary dictionaryWithContentsOfFile:self.downloadFileManager.taskDataPlistPath];
    [data_dic setValue:@{DDQFileManagerTaskSizeKey:@(response_length)} forKey:[self.downloadFileManager file_getTaskFileNameWithUrl:operation.download_address]];
    [data_dic writeToFile:self.downloadFileManager.taskDataPlistPath atomically:YES];
    
    //允许后台下载
    completionHandler(NSURLSessionResponseAllow);
}


- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    
    DDQDownloadOperation *operation = [self manager_getURLLastPathComponent:dataTask.currentRequest.URL];
    
    //写入数据
    [operation.output_stream write:data.bytes maxLength:data.length];
    
    //进度计算
    NSUInteger received = [self.downloadFileManager file_getTaskFileSizeWithUrl:operation.download_address];
    NSUInteger expected = operation.total_length;
    float schedule = 1.0 * received / expected;

    //进度回调
    if (operation.download_schedule) {
        
        operation.download_schedule(received, expected, schedule);
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    
    DDQDownloadOperation *operation = [self manager_getURLLastPathComponent:task.currentRequest.URL];
    
    if (!operation) return;
    
    //下载完成并且没有错误
    if ([self manager_downloadTaskCompletedWithURL:operation.download_address] && !error) {
        // 下载完成
        operation.download_state(kDownloadCompleted);
    }
    
    // 关闭流
    [operation.output_stream close];
    operation.output_stream = nil;
    
    // 清除任务
    [managerTaskDic removeObjectForKey:operation.download_address.lastPathComponent];
    
    if (error){
        
        // 下载失败
        operation.download_state(kDownloadFailed);
        
        if (self.downloadError) {//错误回调不为空
            
            self.downloadError(error);
        }
    }
    
    operation = nil;
    dispatch_suspend(self.timer_t);
}

- (void)dealloc {

    dispatch_cancel(self.timer_t);
}

@end
