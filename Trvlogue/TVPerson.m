//
//  Person.m
//  Trvlogue
//
//  Created by Rohan Kapur on 2/6/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import "TVPerson.h"

@interface NSArray (Indexing)

- (int)indexOfFlight:(TVFlight *)flight;

@end

@implementation NSArray (Indexing)

- (int)indexOfFlight:(TVFlight *)flight {
    
    int retVal = NSNotFound;
    
    for (int i = 0; i <= self.count - 1; i++) {
        
        if ([((TVFlight *)self[i]).ID isEqualToString:flight.ID]) {
            
            retVal = i;
        }
    }
    
    return retVal;
}

@end

@implementation TVPerson
@synthesize name, email, position, miles, originCity, connections, notifications, flights;

#pragma mark Flight Operations

- (NSMutableArray *)sortedFlights {
    
    NSSortDescriptor *sortByDate = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO];
    
    NSMutableArray *_flights = [flights mutableCopy];
    [_flights sortUsingDescriptors:@[sortByDate]];
    
    return _flights;
}

- (void)addFlight:(TVFlight *)flight {
    
    [self.flights addObject:flight];
    
    double _miles = 0.0;
    
    for (TVFlight *flight in self.flights) {
        
        _miles += flight.miles;
    }
    
    self.miles = _miles;
}

- (void)deleteFlight:(TVFlight *)_flight {
    
    NSMutableIndexSet *indexesToRemove = [[NSMutableIndexSet alloc] init];
    
    for (int i = 0; i <= self.flights.count - 1; i++) {
        
        TVFlight *flight = self.flights[i];
        
        if ([flight.ID isEqualToString:_flight.ID]) {
            
            [TVDatabase removeTravelDataPacketWithID:flight.ID];
            [indexesToRemove addIndex:i];
        }
    }
    
    [self.flights removeObjectsAtIndexes:indexesToRemove];
    
    double _miles = 0.0;
    
    for (TVFlight *flight in self.flights) {
        
        _miles += flight.miles;
    }
    
    self.miles = _miles;
}

- (NSMutableArray *)mileTidbits {
    
    return [TVMileTidbits getTidbitsFrom:self.miles];
}

#pragma mark Profile Picture

- (UIImage *)getProfilePic {
    
    NSString *pngPath = [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"Documents/ProfilePicture_%@.png", self.email]];
        
    return [UIImage imageWithContentsOfFile:pngPath];
}

- (void)writeProfilePictureLocally:(UIImage *)profilePicture {
    
    NSString *pngPath = [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"Documents/ProfilePicture_%@.png", self.email]];
        
    [UIImageJPEGRepresentation(profilePicture, 1.0) writeToFile:pngPath atomically:NO];
}

#pragma mark Initialization

- (void)encodeWithCoder:(NSCoder *)coder {
    
    [coder encodeObject:[self name] forKey:@"name"];
    [coder encodeObject:[self email] forKey:@"email"];
    
    [coder encodeDouble:[self miles] forKey:@"miles"];
    
    [coder encodeObject:[self originCity] forKey:@"originCity"];
    
    [coder encodeObject:[self position] forKey:@"job"];
    
    [coder encodeObject:[self connections] forKey:@"connections"];
    
    [coder encodeObject:[self notifications] forKey:@"notifications"];
    
    [coder encodeObject:[self flights] forKey:@"flights"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    
    self = [super init];
    
    if (self) {

        self.name = [aDecoder decodeObjectForKey:@"name"];
        self.email = [aDecoder decodeObjectForKey:@"email"];
                
        self.miles = [aDecoder decodeDoubleForKey:@"miles"];
    
        self.originCity = [aDecoder decodeObjectForKey:@"originCity"];
        
        self.position = [aDecoder decodeObjectForKey:@"job"];
        
        self.connections = [aDecoder decodeObjectForKey:@"connections"];
        
        self.notifications = [aDecoder decodeObjectForKey:@"notifications"];
        
        self.flights = [aDecoder decodeObjectForKey:@"flights"];
    }
    
    return self;
}

- (id)initWithProfile:(NSDictionary *)profileDictionary {
    
    self = [super init];
    
    if (self) {
        
        self.name = profileDictionary[@"name"];
        self.email = profileDictionary[@"email"];
                        
        self.miles = [profileDictionary[@"miles"] doubleValue];
        
        self.originCity = profileDictionary[@"originCity"];
        
        self.position = profileDictionary[@"position"];
        
        self.connections = profileDictionary[@"connections"];
        
        self.notifications = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (NSString *)description {
    
    return [NSString stringWithFormat:@"Name:%@\rEmail:%@\rMiles:%f\r\r%@\r\r%@\r\rFlights:\r%@", self.name, self.email, self.miles, self.position, self.originCity, self.flights];
}

@end
