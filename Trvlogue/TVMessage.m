//
//  TVMessage.m
//  Trvlogue
//
//  Created by Rohan Kapur on 14/8/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import "TVMessage.h"

@implementation TVMessage
@synthesize body, publishDate, receiverRead, senderId, receiverId, ID;

#pragma mark NSCoding Methods

- (void)encodeWithCoder:(NSCoder *)aCoder {
    
    [aCoder encodeObject:self.body forKey:@"body"];
    [aCoder encodeObject:self.publishDate forKey:@"publishDate"];
    [aCoder encodeBool:self.receiverRead forKey:@"receiverRead"];
    [aCoder encodeObject:self.senderId forKey:@"senderId"];
    [aCoder encodeObject:self.receiverId forKey:@"receiverId"];
    [aCoder encodeObject:self.ID forKey:@"ID"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    
    if (self = [self init]) {
        
        self.body = [aDecoder decodeObjectForKey:@"body"];
        self.publishDate = [aDecoder decodeObjectForKey:@"publishDate"];
        self.receiverRead = [aDecoder decodeBoolForKey:@"receiverRead"];
        self.ID = [aDecoder decodeObjectForKey:@"ID"];
        self.senderId = [aDecoder decodeObjectForKey:@"senderId"];
        self.receiverId = [aDecoder decodeObjectForKey:@"receiverId"];
    }
    
    return self;
}

#pragma mark Initialization

- (id)init {
    
    if (self = [super init]) {
        
    }
    
    return self;
}

- (id)initWithBody:(NSString *)_body publishDate:(NSDate *)_publishDate senderId:(NSString *)_senderId andReceiverId:(NSString *)_receiverId {
    
    if (self = [self init]) {
        
        self.body = _body;
        self.publishDate = _publishDate;
        self.senderId = _senderId;
        self.receiverId = _receiverId;
                
        self.ID = [NSString stringWithFormat:@"%@->%@-%@", self.senderId, self.receiverId, self.publishDate];
    }

    return self;
}

- (NSString *)description {
    
    return self.body;
}

@end
