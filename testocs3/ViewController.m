//
//  ViewController.m
//  testocs3
//
//  Created by yuliyang on 2018/3/6.
//  Copyright © 2018年 com.yuliyang. All rights reserved.
//

#import "ViewController.h"
#import <AWSS3/AWSS3.h>
#import <AWSCore/AWSCore.h>

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *uploadImageView;

@end

@implementation ViewController

//获取本地Home目录
- (NSString *)getDocumentDirectory {
    NSString * path = NSHomeDirectory();
    NSLog(@"NSHomeDirectory:%@",path);
    NSString * userName = NSUserName();
    NSString * rootPath = NSHomeDirectoryForUser(userName);
    NSLog(@"NSHomeDirectoryForUser:%@",rootPath);
    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString * documentsDirectory = [paths objectAtIndex:0];
    return documentsDirectory;
}
//创建本地文件用于上传
- (void) createlocalfiles {
    NSFileManager * fm = [NSFileManager defaultManager];
    NSString * mainDir = [self getDocumentDirectory];
    
    NSArray * fileNameArray = @[@"file1k", @"file10k", @"file512k", @"file1m", @"file10m", @"fileDirA/", @"fileDirB/"];
    NSArray * fileSizeArray = @[@1024, @10240, @524288, @1024000, @10240000, @1024, @1024];
    
    NSMutableData * basePart = [NSMutableData dataWithCapacity:1024];
    for (int i = 0; i < 1024/4; i++) {
        u_int32_t randomBit = 10;
        [basePart appendBytes:(void*)&randomBit length:4];
    }
    
    for (int i = 0; i < [fileNameArray count]; i++) {
        NSString * name = [fileNameArray objectAtIndex:i];
        long size = [[fileSizeArray objectAtIndex:i] longValue];
        NSString * newFilePath = [mainDir stringByAppendingPathComponent:name];
        if ([fm fileExistsAtPath:newFilePath]) {
            [fm removeItemAtPath:newFilePath error:nil];
        }
        [fm createFileAtPath:newFilePath contents:nil attributes:nil];
        NSFileHandle * f = [NSFileHandle fileHandleForWritingAtPath:newFilePath];
        for (int k = 0; k < size/1024; k++) {
            [f writeData:basePart];
        }
        [f closeFile];
    }
}
//上传对象
- (void) testupload {
    [self createlocalfiles];
    [self testputobject];
}


- (void) testAWSS3TransferManager {
    NSString * endpoint = @"https://eos-beijing-1.cmecloud.cn";
    NSString * access_key = @"您的access key";
    NSString * secret_key = @"您的secret key";
    AWSStaticCredentialsProvider *credentialsProvider = [[AWSStaticCredentialsProvider alloc]
                                                         initWithAccessKey: access_key
                                                         secretKey : secret_key];
    
    AWSEndpoint *customEndpoint = [[AWSEndpoint alloc]initWithURLString: endpoint];
    AWSServiceConfiguration *serviceConfiguration = [[AWSServiceConfiguration alloc]
                                                     initWithRegion:AWSRegionUSEast1
                                                     endpoint:customEndpoint
                                                     credentialsProvider:credentialsProvider];
    
    //上传
    //    [self createlocalfiles];
    //    [AWSS3TransferManager registerS3TransferManagerWithConfiguration:serviceConfiguration forKey:@"customendpoint"];
    //    // get our TransferManager instance
    //
    //    AWSS3TransferManagerUploadRequest *req = [AWSS3TransferManagerUploadRequest new];
    //    req.body =  [NSURL fileURLWithPath:[[self getDocumentDirectory] stringByAppendingPathComponent:@"file10m"]];
    //    req.contentLength = [NSNumber numberWithUnsignedInteger: 10240000];
    //    req.bucket = @"iosonesttest";
    //    req.key = @"file10m";
    //
    //    AWSS3TransferManager *transferManager = [AWSS3TransferManager S3TransferManagerForKey:@"customendpoint"];
    //
    //    [[[transferManager upload:req] continueWithBlock:^id(AWSTask *task) {
    //        if (task.error) {
    //            NSLog(@"failed");
    //        } else {
    //            NSLog(@"success");
    //        }
    //        return nil;
    //    }] waitUntilFinished];
    
    //下载
    [AWSS3TransferManager registerS3TransferManagerWithConfiguration:serviceConfiguration
                                                              forKey:@"customendpoint"];
    AWSS3TransferManagerDownloadRequest *req = [AWSS3TransferManagerDownloadRequest new];
    req.bucket = @"iosonesttest";
    req.key = @"file10m";
    NSString *downloadFileName = @"download";
    AWSS3TransferManager *transferManager = [AWSS3TransferManager S3TransferManagerForKey:@"customendpoint"];
    
    [[[transferManager download:req] continueWithBlock:^id(AWSTask *task) {
        if (task.error) {
            NSLog(@"failed");
        } else {
            NSLog(@"success");
        }
        return nil;
    }] waitUntilFinished];
}

//上传对象
- (void) testputobject {
    [self createlocalfiles];
    NSString * endpoint = @"https://eos-beijing-1.cmecloud.cn";
    NSString * access_key = @"您的access key";
    NSString * secret_key = @"您的secret key";
    AWSStaticCredentialsProvider *credentialsProvider = [[AWSStaticCredentialsProvider alloc]
                                                         initWithAccessKey: access_key
                                                         secretKey : secret_key];
    
    AWSEndpoint *customEndpoint = [[AWSEndpoint alloc] initWithURLString: endpoint];
    AWSServiceConfiguration *serviceConfiguration = [[AWSServiceConfiguration alloc]initWithRegion:AWSRegionUSEast1 endpoint:customEndpoint credentialsProvider:credentialsProvider];
    
    [AWSS3 registerS3WithConfiguration:serviceConfiguration forKey:@"customendpoint"];
    AWSS3 *s3 = [AWSS3 S3ForKey:@"customendpoint"];
    AWSS3PutObjectRequest *putObjectRequest = [AWSS3PutObjectRequest new];
    putObjectRequest.key = @"objectname10m-1";
    putObjectRequest.bucket = @"iosonesttest";
    
//字符串内容
    NSString *testObjectStr = @"a test object string.";
    NSData *testObjectData = [testObjectStr dataUsingEncoding:NSUTF8StringEncoding];
    putObjectRequest.body =  testObjectData;
    putObjectRequest.contentLength = [NSNumber numberWithUnsignedInteger:[testObjectData length]];
    putObjectRequest.contentType = @"video/mpeg";
//或者本地文件
//    putObjectRequest.body =  [NSURL fileURLWithPath:[[self getDocumentDirectory] stringByAppendingPathComponent:@"file10m"]];
//    putObjectRequest.contentLength = [NSNumber numberWithUnsignedInteger: 10240000];
//    putObjectRequest.body = nil;

    [[[s3 putObject:putObjectRequest] continueWithBlock:^id(AWSTask *task) {
        if (task.error) {
            NSLog(@"failed");
        } else {
            NSLog(@"success");
        }
        return nil;
    }] waitUntilFinished];
}
//创建桶
- (void) testcreatebucket {
    NSString * endpoint = @"https://eos-beijing-1.cmecloud.cn";
    NSString * access_key = @"您的access key";
    NSString * secret_key = @"您的secret key";
    
    AWSStaticCredentialsProvider *credentialsProvider = [[AWSStaticCredentialsProvider alloc]
                                                         initWithAccessKey: access_key
                                                         secretKey : secret_key];
    AWSEndpoint *customEndpoint = [[AWSEndpoint alloc]initWithURLString: endpoint];
    AWSServiceConfiguration *serviceConfiguration = [[AWSServiceConfiguration alloc]
                                                     initWithRegion:AWSRegionUSEast1
                                                     endpoint:customEndpoint
                                                     credentialsProvider:credentialsProvider];
    [AWSS3 registerS3WithConfiguration:serviceConfiguration forKey:@"customendpoint"];
    AWSS3 *s3 = [AWSS3 S3ForKey:@"customendpoint"];
    AWSS3CreateBucketRequest *createBucketReq = [AWSS3CreateBucketRequest new];
    createBucketReq.bucket = @"createbyios";
    AWSS3CreateBucketConfiguration *createBucketConfiguration = [AWSS3CreateBucketConfiguration new];
    createBucketConfiguration.locationConstraint = AWSS3BucketLocationConstraintCNBeijing1; //在数据中心beijing1创建
    createBucketReq.createBucketConfiguration = createBucketConfiguration;
    
    [[[s3 createBucket:createBucketReq] continueWithBlock:^id(AWSTask *task) {
        if (task.error) {
            NSLog(@"failed");
        } else {
            NSLog(@"success");
        }
        return nil;
    }] waitUntilFinished];
}

//列出桶
- (void) testlistbucket {
    NSString * endpoint = @"https://eos-beijing-1.cmecloud.cn";
    NSString * access_key = @"您的access key";
    NSString * secret_key = @"您的secret key";
    AWSStaticCredentialsProvider *credentialsProvider = [[AWSStaticCredentialsProvider alloc]
                                                         initWithAccessKey: access_key
                                                         secretKey : secret_key];
    AWSEndpoint *customEndpoint = [[AWSEndpoint alloc]initWithURLString: endpoint];
    AWSServiceConfiguration *serviceConfiguration = [[AWSServiceConfiguration alloc]
                                                     initWithRegion:AWSRegionUSEast1
                                                     endpoint:customEndpoint
                                                     credentialsProvider:credentialsProvider];
    
    [AWSS3 registerS3WithConfiguration:serviceConfiguration forKey:@"customendpoint"];
    AWSS3 *s3 = [AWSS3 S3ForKey:@"customendpoint"];
    [[[s3 listBuckets:[AWSRequest new]] continueWithBlock:^id(AWSTask *task) {
        AWSS3ListBucketsOutput *listBucketOutput = task.result;
        AWSDDLogDebug(@" testListBucket ========= responseObject is: ================  %@", [listBucketOutput description]);
        return nil;
    }] waitUntilFinished];
}

//删除桶
- (void) testdeletebucket {
    NSString * endpoint = @"https://eos-beijing-1.cmecloud.cn";
    NSString * access_key = @"您的access key";
    NSString * secret_key = @"您的secret key";
    
    AWSStaticCredentialsProvider *credentialsProvider = [[AWSStaticCredentialsProvider alloc] initWithAccessKey: access_key secretKey : secret_key];
    AWSEndpoint *customEndpoint = [[AWSEndpoint alloc]initWithURLString: endpoint];
    AWSServiceConfiguration *serviceConfiguration = [[AWSServiceConfiguration alloc]initWithRegion:AWSRegionUSEast1 endpoint:customEndpoint credentialsProvider:credentialsProvider];
    [AWSS3 registerS3WithConfiguration:serviceConfiguration forKey:@"customendpoint"];
    AWSS3 *s3 = [AWSS3 S3ForKey:@"customendpoint"];
    AWSS3CreateBucketRequest *createBucketReq = [AWSS3CreateBucketRequest new];
    createBucketReq.bucket = @"createbyios";
    [[[s3 createBucket:createBucketReq] continueWithBlock:^id(AWSTask *task) {
        if (task.error) {
            NSLog(@"failed to create bucket");
        } else {
            NSLog(@"success to create bucket");
        }
        return nil;
    }] waitUntilFinished];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //列出桶
//    [self testlistbucket];
    
    //创建桶
//    [self testcreatebucket];
    
    //普通上传对象
    [self testputobject];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
