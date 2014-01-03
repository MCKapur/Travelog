//
//  LinkedInDataRetriever.h
//  Trvlogue
//
//  Created by Rohan Kapur on 27/5/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "LIALinkedInHttpClient.h"
#import "LIALinkedInApplication.h"
#import "AFHTTPRequestOperation.h"

@interface LinkedInDataRetriever : NSObject

+ (void)downloadProfileWithAccessToken: (NSString *)accessToken andCompletionHandler: (void (^)(NSDictionary *profile, BOOL success, NSError *error))callback;
+ (void)downloadConnectionsWithAccessToken: (NSString *)accessToken andCompletionHandler: (void (^)(NSArray *connections, BOOL success, NSError *error))callback;

@end
