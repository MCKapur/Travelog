//
//  DateString.m
//  Trvlogue
//
//  Created by Rohan Kapur on 20/3/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import "DateString.h"

@implementation DateString

+ (NSString *)convertDateToString:(NSDate *)date withFormat: (NSString *)format {
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    
    [dateFormatter setDateFormat: format];
    
    return [dateFormatter stringFromDate: date];
}

+ (NSDate *)convertStringToDate:(NSString *)dateString withFormat: (NSString *)format {
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    
    [dateFormatter setDateFormat: format];
    
    return [dateFormatter dateFromString: dateString];
}

@end
