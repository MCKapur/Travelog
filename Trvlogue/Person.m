//
//  Person.m
//  Trvlogue
//
//  Created by Rohan Kapur on 2/6/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import "Person.h"

@implementation Person
@synthesize name, email, position, miles, originCity, connections, notifications;

- (NSMutableArray *)mileTidbits {
    
    return [MileTidbits getTidbitsFrom:self.miles];
}

- (UIImage *)getProfilePic {
    
    NSString *pngPath = [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"Documents/ProfilePicture_%@.png", self.email]];
        
    return [UIImage imageWithContentsOfFile:pngPath];
}

- (void)writeProfilePictureLocally:(UIImage *)profilePicture {
    
    NSString *pngPath = [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"Documents/ProfilePicture_%@.png", self.email]];
        
    [UIImageJPEGRepresentation(profilePicture, 1.0) writeToFile:pngPath atomically:NO];
}

- (void)encodeWithCoder:(NSCoder *)coder {
    
    [coder encodeObject:[self name] forKey:@"name"];
    [coder encodeObject:[self email] forKey:@"email"];
    
    [coder encodeDouble:[self miles] forKey:@"miles"];
    
    [coder encodeObject:[self originCity] forKey:@"originCity"];
    
    [coder encodeObject:[self position] forKey:@"job"];
    
    [coder encodeObject:[self connections] forKey:@"connections"];
    
    [coder encodeObject:[self notifications] forKey:@"notifications"];
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
    
    return [NSString stringWithFormat:@"Name:%@\rEmail:%@\rMiles:%f\r\r%@\r\r%@", self.name, self.email, self.miles, self.position, self.originCity];
}

@end
