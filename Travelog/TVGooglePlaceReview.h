//
//  GooglePlaceReview.h
//  Trvlogue
//
//  Created by Upi Kapur on 26/7/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TVGooglePlaceReview : NSObject <NSCoding>

@property (nonatomic, strong) NSMutableArray *aspects;
@property (nonatomic, strong) NSString *authorName;
@property (nonatomic, strong) NSString *authorURL;
@property (nonatomic, strong) NSString *body;
@property (nonatomic) NSInteger time;

@end
