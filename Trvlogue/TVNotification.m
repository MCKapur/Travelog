//
//  TrvlogueNotification.m
//  Trvlogue
//
//  Created by Rohan Kapur on 9/6/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import "TVNotification.h"

@implementation TVNotification
@synthesize type;

- (void)encodeWithCoder:(NSCoder *)aCoder {
 
    [aCoder encodeInt:(int)[self type] forKey:@"type"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    
    self = [super init];
    
    if (self) {
        
        self.type = (NotificationType *)[aDecoder decodeIntForKey:@"type"];
    }
    
    return self;
}

- (id)init {
    
    if (self = [super init]) {
    
    }
    
    return self;
}

- (id)initWithType:(NotificationType *)_type {
    
    if (self = [self init]) {
        
        self.type = _type;
    }
    
    return self;
}

- (NSString *)description {
    
    return [NSString stringWithFormat:@"Type: %i", (int)self.type];
}

@end
