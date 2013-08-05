//
//  TrvlnetAccount.h
//  Trvlogue
//
//  Created by Rohan Kapur on 10/1/13.
//  Copyright (c) 2013 UWCSEA. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TrvlogueFlight.h"

#import "MileTidbits.h"

@interface TrvlogueAccount : NSObject <NSCoding>

@property (nonatomic, strong) Person *person;

@property (nonatomic) BOOL isUsingLinkedIn;
@property (nonatomic, strong) NSString *linkedInAccessKey;
@property (nonatomic, strong) NSString *linkedInId;

@property (nonatomic, strong) NSString *email;
@property (nonatomic, strong) NSString *password;

@property (nonatomic, strong) NSMutableArray *flights;

- (void)addFlight: (TrvlogueFlight *)flight;
- (void)deleteFlight: (TrvlogueFlight *)flight;

- (id)initWithProfile:(NSDictionary *)profileDictionary;

@end
