//
//  MileTidbits.h
//  Trvlogue
//
//  Created by Rohan Kapur on 19/1/13.
//  Copyright (c) 2013 UWCSEA. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Database.h"

@interface MileTidbits : NSObject

+ (NSMutableArray *)getTidbitsFrom:(double)mileIndex;

+ (NSString *)formatTidbit:(double)tidbit;

+ (void)downloadScoreAgainstFriendsWithCompletionHandler:(void (^)(BOOL success, NSError *error, NSDictionary *score))callback;

@end
