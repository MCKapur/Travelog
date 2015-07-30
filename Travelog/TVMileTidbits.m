//
//  MileTidbits.m
//  Trvlogue
//
//  Created by Rohan Kapur on 19/1/13.
//  Copyright (c) 2013 UWCSEA. All rights reserved.
//

#import "TVMileTidbits.h"

@implementation TVMileTidbits

+ (NSMutableArray *)getTidbitsFrom:(double)mileIndex {
        
    NSInteger numberOfFlights = [[[[TVDatabase currentAccount] person] flights] count];
    NSInteger timeInAirports = [[[[TVDatabase currentAccount] person] flights] count] * 2;
    double kilometers = mileIndex * 1.609344;
    double meters = kilometers * 1000;
    double centimeters = meters * 100;
    double toTheMoon = mileIndex / 251872;
    double aroundTheEarth = mileIndex /  24901.55;
    double hoursInTheAir = mileIndex / 530;
    double toTheOzoneLayer = mileIndex / 47;
    double toTheCore = mileIndex / 3959;
    
    NSMutableArray *tidbits = [@[@{@"name": @"miles", @"value": @(mileIndex)}, @{@"name": @"flights", @"value": @(numberOfFlights)}, @{@"name": @"kilometers", @"value": @(kilometers)}, @{@"name": @"meters", @"value": @(meters)}, @{@"name": @"centimeters", @"value": @(centimeters)}, @{@"name": @"hours spent in airports", @"value": @(timeInAirports)}, @{@"name": @"hours in an airplane", @"value": @(hoursInTheAir)}] mutableCopy];
    
    if (toTheMoon >= 0.1) {
        
        [tidbits addObject:@{@"name": @"times to the moon!", @"value": @(toTheMoon)}];
    }
    
    if (toTheOzoneLayer >= 0.1) {
        
        [tidbits addObject:@{@"name": @"times to the ozone layer", @"value": @(toTheOzoneLayer)}];
    }
    
    if (toTheCore >= 0.1) {
        
        [tidbits addObject:@{@"name": @"times to the Earth's core", @"value": @(toTheCore)}];
    }
    
    if (aroundTheEarth >= 0.1) {
        
        [tidbits addObject:@{@"name": @"times around the Earth", @"value": @(aroundTheEarth)}];
    }
    
    return tidbits;
}

+ (NSString *)formatTidbit:(double)tidbit {
    
    NSNumberFormatter *tidbitFormatter = [[NSNumberFormatter alloc] init];
    [tidbitFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    tidbitFormatter.maximumFractionDigits = 1;
    
    NSString *formattedTidbit = [[tidbitFormatter stringFromNumber:@(tidbit)]stringByReplacingOccurrencesOfString:@"," withString:@", "];
    
    return formattedTidbit;
}

@end