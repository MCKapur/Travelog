//
//  TrvlnetAccount.h
//  Trvlogue
//
//  Created by Rohan Kapur on 10/1/13.
//  Copyright (c) 2013 UWCSEA. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TVFlight.h"

#import "TVMileTidbits.h"

@interface TVAccount : NSObject <NSCoding>

@property (nonatomic, strong) TVPerson *person;

@property (nonatomic) BOOL isUsingLinkedIn;
@property (nonatomic, strong) NSString *linkedInAccessKey;
@property (nonatomic, strong) NSString *linkedInId;

@property (nonatomic, strong) NSString *email;
@property (nonatomic, strong) NSString *password;

@property (nonatomic, strong) NSMutableArray *flights;

- (void)addFlight: (TVFlight *)flight;
- (void)deleteFlight: (TVFlight *)flight;

- (id)initWithProfile:(NSDictionary *)profileDictionary;

- (NSMutableArray *)sortedFlights;

@end
