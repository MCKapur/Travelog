//
//  LinkedInAuthorizer.h
//  Trvlogue
//
//  Created by Rohan Kapur on 27/5/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "LIALinkedInHttpClient.h"
#import "LIALinkedInApplication.h"
#import "AFHTTPRequestOperation.h"

@interface LinkedInAuthorizer : NSObject

+ (void)authorizeWithCompletionHandler:(void (^)(BOOL succeeded, BOOL cancelled, NSError *error, NSString *accessToken))callback;

@end