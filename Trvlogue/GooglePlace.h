//
//  GooglePlace.h
//  Trvlogue
//
//  Created by Upi Kapur on 26/7/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GooglePlace : NSObject

@property (nonatomic, strong) NSString *ID;
@property (nonatomic, strong) NSString *reference;
@property (nonatomic, strong) NSString *name;

@property (nonatomic, strong) NSString *longAddress;
@property (nonatomic, strong) NSString *shortAddress;
@property (nonatomic) CLLocationCoordinate2D coordinate;

@property (nonatomic, strong) NSString *phoneNumber;

@property (nonatomic, strong) NSString *website;

@property (nonatomic, strong) NSString *icon;
@property (nonatomic, strong) NSMutableArray *photos;

@property (nonatomic) double rating;
@property (nonatomic, strong) NSMutableArray *reviews;


@property (nonatomic) int priceLevel;

@end
