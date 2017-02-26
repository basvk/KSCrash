//
//  KSCrashReportSinkStandardWithAppleFmt.m
//  KSCrash-iOS
//
//  Created by Bas vK on 26/02/17.
//  Copyright © 2017 Bas vK. All rights reserved.
//

#import "KSCrashReportSinkStandardWithAppleFmt.h"
#import "KSHTTPMultipartPostBody.h"
#import "KSHTTPRequestSender.h"
#import "NSData+GZip.h"
#import "KSJSONCodecObjC.h"
#import "KSReachabilityKSCrash.h"
#import "NSError+SimpleConstructor.h"
#import "KSCrashReportFilterAppleFmt.h"
#import "KSCrashReportFilterBasic.h"
#import "KSCrashReportFilterGZip.h"

//#define KSLogger_LocalLevel TRACE
#import "KSLogger.h"


@interface KSCrashReportSinkStandardWithAppleFmt ()

@property(nonatomic,readwrite,retain) NSURL* url;

@property(nonatomic,readwrite,retain) KSReachableOperationKSCrash* reachableOperation;


@end



@implementation KSCrashReportSinkStandardWithAppleFmt

@synthesize url = _url;
@synthesize reachableOperation = _reachableOperation;

+ (KSCrashReportSinkStandardWithAppleFmt*) sinkWithURL:(NSURL*) url
{
    return [[self alloc] initWithURL:url];
}

- (id) initWithURL:(NSURL*) url
{
    if((self = [super init]))
    {
        self.url = url;
    }
    return self;
}

- (id <KSCrashReportFilter>) defaultCrashReportFilterSet
{
    return [KSCrashReportFilterPipeline filterWithFilters:
            [KSCrashReportFilterAppleFmt filterWithReportStyle:KSAppleReportStyleSymbolicatedSideBySide],
            [KSCrashReportFilterStringToData filter],
            self,
            nil];
}

- (void) filterReports:(NSArray*) reports
          onCompletion:(KSCrashReportFilterCompletion) onCompletion
{
    
    NSError* error = nil;
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:self.url
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                       timeoutInterval:15];
    
    NSMutableData *concatenatedReports = [NSData data].mutableCopy;
    
    [reports enumerateObjectsUsingBlock:^(NSData * _Nonnull report, NSUInteger idx, BOOL * _Nonnull stop) {
        [concatenatedReports appendData:report];
        
        if (idx < reports.count - 1) {
            [concatenatedReports appendData:[@"\014" dataUsingEncoding:NSASCIIStringEncoding]];
        }
    }];
    
    KSHTTPMultipartPostBody* body = [KSHTTPMultipartPostBody body];

    [body appendData:concatenatedReports
                name:@"reports"
         contentType:@"text/plain"
            filename:@"reports.crash"];
    // TODO: Disabled gzip compression until support is added server side,
    // and I've fixed a bug in appendUTF8String.
    //    [body appendUTF8String:@"json"
    //                      name:@"encoding"
    //               contentType:@"string"
    //                  filename:nil];
    
    request.HTTPMethod = @"POST";
    request.HTTPBody = [body data];
    [request setValue:body.contentType forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"KSCrashReporter" forHTTPHeaderField:@"User-Agent"];
    
    //    [request setHTTPBody:[[body data] gzippedWithError:nil]];
    //    [request setValue:@"gzip" forHTTPHeaderField:@"Content-Encoding"];
    
    self.reachableOperation = [KSReachableOperationKSCrash operationWithHost:[self.url host]
                                                                   allowWWAN:YES
                                                                       block:^
                               {
                                   [[KSHTTPRequestSender sender] sendRequest:request
                                                                   onSuccess:^(__unused NSHTTPURLResponse* response, __unused NSData* data)
                                    {
                                        kscrash_callCompletion(onCompletion, reports, YES, nil);
                                    } onFailure:^(NSHTTPURLResponse* response, NSData* data)
                                    {
                                        NSString* text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                                        kscrash_callCompletion(onCompletion, reports, NO,
                                                               [NSError errorWithDomain:[[self class] description]
                                                                                   code:response.statusCode
                                                                            description:text]);
                                    } onError:^(NSError* error2)
                                    {
                                        kscrash_callCompletion(onCompletion, reports, NO, error2);
                                    }];
                               }];
}

@end
