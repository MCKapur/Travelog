//
//  PeopleFeed.m
//  Trvlogue
//
//  Created by Rohan Kapur on 10/5/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import "PeopleFeed.h"

@implementation PeopleFeed

+ (void)findPeopleFromFlight:(NSString *)flightID withCompletionHandler:(void (^)(NSMutableArray *objects, NSError *error, NSString *callCode))callback {
    
    [Database isCreatingAnAccount:NO];

    [Database downloadConnectionsInTheSameCity:flightID withCompletionHandler:^(NSMutableArray *objects, NSError *error, NSString *callCode) {
         
        callback(objects, error, callCode);
    }];
}

@end