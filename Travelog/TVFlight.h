//
//  Flight.h
//  Trvlogue
//
//  Created by Rohan Kapur on 19/1/13.
//  Copyright (c) 2013 UWCSEA. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <CoreLocation/CoreLocation.h>

#import "TVTravelDataDownloader.h"

#import "TVFlightDetailViewController.h"

@interface TVFlight : NSObject <NSCoding, TravelDataDelegate>

@property (nonatomic, strong) NSString *ID;

@property (nonatomic) CLLocationCoordinate2D originCoordinate;
@property (nonatomic) CLLocationCoordinate2D destinationCoordinate;
@property (nonatomic) CGFloat miles;

@property (nonatomic, strong) NSString *originCity;
@property (nonatomic, strong) NSString *destinationCity;
@property (nonatomic, strong) NSString *originCountry;
@property (nonatomic, strong) NSString *destinationCountry;

@property (nonatomic, strong) NSDate *date;

- (id)initWithParameters: (NSDictionary *)dictionary;

- (void)instantiateTravelData;

@end
