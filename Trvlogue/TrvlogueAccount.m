//
//  TrvlnetAccount.m
//  Trvlogue
//
//  Created by Rohan Kapur on 10/1/13.
//  Copyright (c) 2013 UWCSEA. All rights reserved.
//

#import "TrvlogueAccount.h"

@implementation TrvlogueAccount
@synthesize email, password, flights, isUsingLinkedIn, linkedInAccessKey, linkedInId, person;

- (void)encodeWithCoder:(NSCoder *)coder {
        
    [coder encodeObject:[self email] forKey:@"email"];
    [coder encodeObject:[self password] forKey:@"password"];

    [coder encodeObject:[self flights] forKey:@"flights"];
    
    [coder encodeObject:[self person] forKey:@"person"];
    
    [coder encodeBool:[self isUsingLinkedIn] forKey:@"isUsingLinkedIn"];
    [coder encodeObject:[self linkedInAccessKey] forKey:@"linkedInAccessKey"];
    [coder encodeObject:[self linkedInId] forKey:@"linkedInId"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
 
    self = [super init];
    
    if (self) {
        
        self.flights = [aDecoder decodeObjectForKey:@"flights"];
        
        self.email = [aDecoder decodeObjectForKey:@"email"];
        self.password = [aDecoder decodeObjectForKey:@"password"];
                
        self.isUsingLinkedIn = [aDecoder decodeBoolForKey:@"isUsingLinkedIn"];
        self.linkedInAccessKey = [aDecoder decodeObjectForKey:@"linkedInAccessKey"];
        self.linkedInId = [aDecoder decodeObjectForKey:@"linkedInId"];
        
        self.person = [aDecoder decodeObjectForKey:@"person"];
    }

    return self;
}

- (id)init {
    
    if (self) {
        
        self.person = [[Person alloc] init];
    }

    return self;
}

- (id)initWithProfile:(NSDictionary *)profileDictionary {
    
    self = [super init];
    
    if (self) {
        
        self.person = [[Person alloc] init];
        
        self.person.name = profileDictionary[@"name"];
        
        self.person.email = profileDictionary[@"email"];
        self.email = profileDictionary[@"email"];
                
        self.password = profileDictionary[@"password"];
        
        self.person.connections = profileDictionary[@"connections"];
                                                
        self.person.miles = [profileDictionary[@"miles"] doubleValue];
        
        self.flights = profileDictionary[@"flights"];
        
        self.person.knownDestinationPreferences = profileDictionary[@"knownDestinationPreferences"];
                
        self.person.originCity = profileDictionary[@"originCity"];

        self.person.position = profileDictionary[@"position"];
        
        self.isUsingLinkedIn = [profileDictionary[@"isUsingLinkedIn"] boolValue];
        self.linkedInAccessKey = profileDictionary[@"linkedInAccessKey"];
        self.linkedInId = profileDictionary[@"linkedInId"];
    }
    
    return self;
}

- (NSMutableArray *)flights {
    
    NSSortDescriptor *sortByDate = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES];
    [flights sortUsingDescriptors:[NSArray arrayWithObject:sortByDate]];
    
    return flights;
}

- (void)addFlight:(TrvlogueFlight *)flight {
    
    [self.flights addObject:flight];

    double miles = 0.0;
    
    for (TrvlogueFlight *flight in self.flights) {
        
        miles += flight.miles;
    }
    
    self.person.miles = miles;
}

- (void)deleteFlight:(TrvlogueFlight *)_flight {
    
    NSMutableIndexSet *indexesToRemove = [[NSMutableIndexSet alloc] init];
    
    for (int i = 0; i <= self.flights.count - 1; i++) {
        
        TrvlogueFlight *flight = self.flights[i];
        
        if ([flight.ID isEqualToString:_flight.ID]) {
            
            self.person.miles -= flight.miles;
            [Database removeTravelDataPacketWithID:flight.ID];
            [indexesToRemove addIndex:i];
        }
    }
    
    [self.flights removeObjectsAtIndexes:indexesToRemove];
}

- (NSString *)description {
    
    return [NSString stringWithFormat:@"%@", self.person];
}

@end
