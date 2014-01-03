//
//  DateString.h
//  Trvlogue
//
//  Created by Rohan Kapur on 20/3/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TVConversions : NSObject

+ (NSDate *)convertStringToDate: (NSString *)dateString withFormat: (NSString *)format;
+ (NSString *)convertDateToString: (NSDate *)date withFormat: (NSString *)format;

@end
