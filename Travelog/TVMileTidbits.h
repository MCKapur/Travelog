//
//  MileTidbits.h
//  Trvlogue
//
//  Created by Rohan Kapur on 19/1/13.
//  Copyright (c) 2013 UWCSEA. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TVDatabase.h"

@interface TVMileTidbits : NSObject

+ (NSMutableArray *)getTidbitsFrom:(double)mileIndex;
+ (NSString *)formatTidbit:(double)tidbit;

@end
