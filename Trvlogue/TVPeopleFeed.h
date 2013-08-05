//
//  PeopleFeed.h
//  Trvlogue
//
//  Created by Rohan Kapur on 10/5/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TVPerson.h"

@interface TVPeopleFeed : NSObject

+ (void)findPeopleFromFlight:(NSString *)flightID withCompletionHandler:(void (^)(NSMutableArray *objects, NSError *error, NSString *callCode))callback;

@end
