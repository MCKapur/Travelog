//
//  PeopleFeed.h
//  Trvlogue
//
//  Created by Rohan Kapur on 10/5/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Person.h"

@interface PeopleFeed : NSObject

+ (void)findPeopleFromFlight:(NSString *)flightID withCompletionHandler:(void (^)(NSMutableArray *objects, NSError *error, NSString *callCode))callback;

@end
