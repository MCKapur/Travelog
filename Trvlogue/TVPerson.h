//
//  Person.h
//  Trvlogue
//
//  Created by Rohan Kapur on 2/6/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TVMileTidbits.h"

#import "TVMessageHistory.h"

@interface TVPerson : NSObject <NSCoding>

@property (nonatomic, strong) NSMutableArray *notifications;

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *email;

@property (nonatomic, strong) NSString *position;

@property (nonatomic) double miles;

@property (nonatomic, strong) NSString *originCity;

@property (nonatomic, strong) NSMutableArray *connections;

@property (nonatomic, strong) NSMutableDictionary *knownDestinationPreferences;

@property (nonatomic, strong) NSMutableArray *flights;

@property (nonatomic, strong) NSMutableArray *messageHistories;

- (void)addFlight: (TVFlight *)flight;
- (void)deleteFlight: (TVFlight *)flight;

- (NSMutableArray *)sortedFlights;

- (NSMutableArray *)mileTidbits;

- (UIImage *)getProfilePic;
- (void)writeProfilePictureLocally:(UIImage *)profilePicture;

@end