//
//  TrvlogueNotification.m
//  Trvlogue
//
//  Created by Rohan Kapur on 9/6/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import "TrvlogueNotification.h"

@implementation TrvlogueNotification
@synthesize title, type;

- (void)encodeWithCoder:(NSCoder *)aCoder {
 
    [aCoder encodeObject:[self title] forKey:@"title"];
    [aCoder encodeInt:(int)[self type] forKey:@"type"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    
    self = [super init];
    
    if (self) {
        
        self.title = [aDecoder decodeObjectForKey:@"title"];
        self.type = (NotificationType *)[aDecoder decodeIntForKey:@"type"];
    }
    
    return self;
}

- (id)init {
    
    if (self = [super init]) {
    
    }
    
    return self;
}

- (id)initWithTitle:(NSString *)_title andType:(NotificationType *)_type {
    
    if (self = [self init]) {
        
        self.title = _title;
        self.type = _type;
    }
    
    return self;
}

- (NSString *)description {
    
    return [NSString stringWithFormat:@"\rTitle: %@\rType: %i", self.title, (int)self.type];
}

@end
