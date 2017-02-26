//
//  KSCrashReportSinkStandardWithAppleFmt.h
//  KSCrash-iOS
//
//  Created by Bas vK on 26/02/17.
//  Copyright © 2017 Karl Stenerud. All rights reserved.
//

#import "KSCrashReportFilter.h"


/**
 * Sends crash reports to an HTTP server.
 *
 * Input: NSDictionary
 * Output: Same as input (passthrough)
 */
@interface KSCrashReportSinkStandardWithAppleFmt : NSObject<KSCrashReportFilter>

/** Constructor.
 *
 * @param url The URL to connect to.
 */
+ (KSCrashReportSinkStandardWithAppleFmt*) sinkWithURL:(NSURL*) url;

/** Constructor.
 *
 * @param url The URL to connect to.
 */
- (id) initWithURL:(NSURL*) url;

- (id <KSCrashReportFilter>) defaultCrashReportFilterSet;

@end
