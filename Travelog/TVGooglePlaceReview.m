//
//  GooglePlaceReview.m
//  Trvlogue
//
//  Created by Upi Kapur on 26/7/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import "TVGooglePlaceReview.h"

@implementation TVGooglePlaceReview
@synthesize aspects, authorName, authorURL, body, time;

- (void)encodeWithCoder:(NSCoder *)aCoder {
    
    [aCoder encodeObject:self.aspects forKey:@"aspects"];
    [aCoder encodeObject:self.authorName forKey:@"authorName"];
    [aCoder encodeObject:self.authorURL forKey:@"authorURL"];
    [aCoder encodeObject:self.body forKey:@"body"];
    [aCoder encodeInt:self.time forKey:@"time"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    
    if (self = [self init]) {
        
        self.aspects = [aDecoder decodeObjectForKey:@"aspects"];
        self.authorName = [aDecoder decodeObjectForKey:@"authorName"];
        self.authorURL = [aDecoder decodeObjectForKey:@"authorURL"];
        self.body = [aDecoder decodeObjectForKey:@"body"];
        self.time = [aDecoder decodeIntForKey:@"time"];
    }
    
    return self;
}

- (id)init {
    
    if (self = [super init]) {
        
    }
    
    return self;
}

@end
