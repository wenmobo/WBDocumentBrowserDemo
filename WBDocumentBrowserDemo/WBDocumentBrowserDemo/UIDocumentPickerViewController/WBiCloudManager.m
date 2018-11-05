//
//  WBiCloudManager.m
//  WBDocumentBrowserDemo
//
//  Created by Mr_Lucky on 2018/11/5.
//  Copyright © 2018 wenbo. All rights reserved.
//

#import "WBiCloudManager.h"
#import "WBDocument.h"

@implementation WBiCloudManager




/*  < 判断是否有iCloud权限 > */
+ (BOOL)iCloudEnable {
    return [self defaultiCloudURL] ? YES : NO;
}

+ (NSURL *)defaultiCloudURL {
    NSURL *url = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    url = [fileManager URLForUbiquityContainerIdentifier:nil];
    return url;
}

/*  < 从iCloud下载文件 > */
+ (void)wb_downloadWithDocumentURL:(NSURL *)url
                    completedBlock:(downloadCallBack)completedBlock {
    WBDocument *document = [[WBDocument alloc]initWithFileURL:url];
    [document openWithCompletionHandler:^(BOOL success) {
        if (success) {
            if (completedBlock) {
                completedBlock(document.data);
            }
            
            [document closeWithCompletionHandler:^(BOOL success) {
                if (success) {
                    NSLog(@"关闭成功");
                }
            }];
        }
    }];
}

+ (NSURL *)wb_createUbiquityContainerURLWithFileName:(NSString *)fileName {
    NSURL *url = [self defaultiCloudURL];
    if (url) {
        NSURL *documentURL = [url URLByAppendingPathComponent:@"Documents"];
        return [documentURL URLByAppendingPathComponent:fileName];
    }
    return nil;
}

// MARK:Public Method
- (BOOL)wb_queryDocumentList {
    if (![[self class] iCloudEnable]) {
        return NO;
    }
    self.dataQuery.searchScopes = @[NSMetadataQueryUbiquitousDocumentsScope];
    self.dataQuery.predicate = [NSPredicate predicateWithValue:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(metadataQueryDidFinishGathering)
                                                 name:NSMetadataQueryDidFinishGatheringNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(metadataQueryDidFinishGathering)
                                                 name:NSMetadataQueryDidUpdateNotification
                                               object:nil];
    [self.dataQuery enableUpdates];
    [self.dataQuery startQuery];
    return YES;
}

- (void)metadataQueryDidFinishGathering {
    NSArray *queryList = self.dataQuery.results;
    if (self.queryDidFinished) {
        self.queryDidFinished(queryList);
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.dataQuery disableUpdates];
    [self.dataQuery stopQuery];
}

- (void)wb_uploadDocumentWithFileName:(NSString *)fileName {
    NSURL *url = [[self class] wb_createUbiquityContainerURLWithFileName:fileName];
    if (url) {
        WBDocument *document = [[WBDocument alloc]initWithFileURL:url];
        document.data = [NSData dataWithContentsOfURL:url];
        [document saveToURL:url
           forSaveOperation:UIDocumentSaveForCreating
          completionHandler:^(BOOL success) {
              if (success) {
                  NSLog(@"保存成功");
              }
          }];
    }
}

// MARK:Getter
- (NSMetadataQuery *)dataQuery {
    if (!_dataQuery) {
        _dataQuery = [[NSMetadataQuery alloc]init];
    }
    return _dataQuery;
}

@end
