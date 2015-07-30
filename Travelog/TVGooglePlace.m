//
//  GooglePlace.m
//  Trvlogue
//
//  Created by Upi Kapur on 26/7/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import "TVGooglePlace.h"

@implementation TVGooglePlace
@synthesize ID, reference, name, address, coordinate, phoneNumber, website, photos, rating, reviews, priceLevel;

#pragma mark Icon

- (void)writeIconLocally:(UIImage *)_icon {
    
    [[EGOCache globalCache] setImage:_icon forKey:[NSString stringWithFormat:@"Place_%@_Icon.png", self.ID]];
}

- (UIImage *)getIcon {
    
   return [[EGOCache globalCache] imageForKey:[NSString stringWithFormat:@"Place_%@_Icon.png", self.ID]];
}

#pragma mark Initialization and NSCoding Methods

- (void)encodeWithCoder:(NSCoder *)aCoder {
    
    [aCoder encodeObject:self.ID forKey:@"ID"];
    [aCoder encodeObject:self.reference forKey:@"reference"];
    [aCoder encodeObject:self.name forKey:@"name"];
    [aCoder encodeObject:self.address forKey:@"address"];
    [aCoder encodeDouble:self.coordinate.latitude forKey:@"coordinate_latitude"];
    [aCoder encodeDouble:self.coordinate.longitude forKey:@"coordinate_longitude"];
    [aCoder encodeObject:self.phoneNumber forKey:@"phoneNumber"];
    [aCoder encodeObject:self.website forKey:@"website"];
    [aCoder encodeObject:self.photos forKey:@"photos"];
    [aCoder encodeInteger:self.rating forKey:@"rating"];
    [aCoder encodeObject:self.reviews forKey:@"reviews"];
    [aCoder encodeInteger:self.priceLevel forKey:@"priceLevel"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    
    if (self = [self init]) {
        
        self.ID = [aDecoder decodeObjectForKey:@"ID"];
        self.reference = [aDecoder decodeObjectForKey:@"reference"];
        self.name = [aDecoder decodeObjectForKey:@"name"];
        self.address = [aDecoder decodeObjectForKey:@"address"];
        self.coordinate = CLLocationCoordinate2DMake([aDecoder decodeDoubleForKey:@"coordinate_latitude"], [aDecoder decodeDoubleForKey:@"coordinate_longitude"]);
        self.phoneNumber = [aDecoder decodeObjectForKey:@"phoneNumber"];
        self.website = [aDecoder decodeObjectForKey:@"website"];
        self.photos = [aDecoder decodeObjectForKey:@"photos"];
        self.rating = [aDecoder decodeIntegerForKey:@"rating"];
        self.reviews = [aDecoder decodeObjectForKey:@"reviews"];
        self.priceLevel = [aDecoder decodeIntegerForKey:@"priceLevel"];
    }
    
    return self;
}

- (id)init {
    
    if (self = [super init]) {
        
    }
    
    return self;
}

- (NSString *)description {
    
    return [NSString stringWithFormat:@"%@ located at %@, call them at %@ and check out their site at %@. Rated %.1f/5.", self.name, self.address, self.phoneNumber, self.website, self.rating];
}

@end
