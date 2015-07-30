//
//  GooglePlace.h
//  Trvlogue
//
//  Created by Upi Kapur on 26/7/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TVGooglePlacePhoto.h"
#import "TVGooglePlaceReview.h"

@interface TVGooglePlace : NSObject <NSCoding>

@property (nonatomic, strong) NSString *ID;
@property (nonatomic, strong) NSString *reference;
@property (nonatomic, strong) NSString *name;

@property (nonatomic, strong) NSString *address;
@property (nonatomic) CLLocationCoordinate2D coordinate;

@property (nonatomic, strong) NSString *phoneNumber;

@property (nonatomic, strong) NSString *website;

@property (nonatomic, strong) NSMutableDictionary *photos;

@property (nonatomic) double rating;
@property (nonatomic, strong) NSMutableArray *reviews;

@property (nonatomic) NSInteger priceLevel;

- (UIImage *)getIcon;
- (void)writeIconLocally:(UIImage *)icon;

@end
