//
//  TrvlogueNotification.m
//  Trvlogue
//
//  Created by Rohan Kapur on 9/6/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import "TVNotification.h"

@implementation TVNotification
@synthesize type, ID;

- (void)encodeWithCoder:(NSCoder *)aCoder {
 
    [aCoder encodeInt:(int)self.type forKey:@"type"];
    [aCoder encodeObject:self.ID forKey:@"ID"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    
    self = [super init];
    
    if (self) {
        
        self.type = (NotificationType *)[aDecoder decodeIntForKey:@"type"];
        self.ID = [aDecoder decodeObjectForKey:@"ID"];
    }
    
    return self;
}

- (id)init {
    
    if (self = [super init]) {
    
    }
    
    return self;
}

- (id)initWithType:(NotificationType *)_type withUserId:(NSString *)userId {

    if (self = [self init]) {
        
        self.type = _type;
        self.ID = [NSString stringWithFormat:@"%@-%@", _type == kNotificationTypeConnectionRequest ? PENDING_CONNECTION_REQUEST : UNREAD_MESSAGE, userId];
    }
    
    return self;
}

- (NSString *)description {
    
    return [NSString stringWithFormat:@"Type: %i", (int)self.type];
}

@end
