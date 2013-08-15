//
//  TrvlnetAccount.m
//  Trvlogue
//
//  Created by Rohan Kapur on 10/1/13.
//  Copyright (c) 2013 UWCSEA. All rights reserved.
//

#import "TVAccount.h"

@implementation TVAccount
@synthesize email, password, isUsingLinkedIn, linkedInAccessKey, linkedInId, person;

- (void)encodeWithCoder:(NSCoder *)coder {
        
    [coder encodeObject:[self email] forKey:@"email"];
    [coder encodeObject:[self password] forKey:@"password"];
    
    [coder encodeObject:[self person] forKey:@"person"];
    
    [coder encodeBool:[self isUsingLinkedIn] forKey:@"isUsingLinkedIn"];
    [coder encodeObject:[self linkedInAccessKey] forKey:@"linkedInAccessKey"];
    [coder encodeObject:[self linkedInId] forKey:@"linkedInId"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
 
    self = [super init];
    
    if (self) {
                
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
        
        self.person = [[TVPerson alloc] init];
    }

    return self;
}

- (id)initWithProfile:(NSDictionary *)profileDictionary {
    
    self = [super init];
    
    if (self) {
        
        self.person = [[TVPerson alloc] init];
        
        self.person.name = profileDictionary[@"name"];
        
        self.person.email = profileDictionary[@"email"];
        self.email = profileDictionary[@"email"];
                
        self.password = profileDictionary[@"password"];
        
        self.person.connections = profileDictionary[@"connections"];
                                                
        self.person.miles = [profileDictionary[@"miles"] doubleValue];
        
        self.person.flights = profileDictionary[@"flights"];
        
        self.person.knownDestinationPreferences = profileDictionary[@"knownDestinationPreferences"];
                
        self.person.originCity = profileDictionary[@"originCity"];

        self.person.position = profileDictionary[@"position"];
        
        self.isUsingLinkedIn = [profileDictionary[@"isUsingLinkedIn"] boolValue];
        self.linkedInAccessKey = profileDictionary[@"linkedInAccessKey"];
        self.linkedInId = profileDictionary[@"linkedInId"];
    }
    
    return self;
}

- (NSString *)description {
    
    return [NSString stringWithFormat:@"%@", self.person];
}

@end
