//
//  TrvlogueMessageHistory.m
//  Trvlogue
//
//  Created by Rohan Kapur on 18/6/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import "TVMessageHistory.h"

@implementation TVMessageHistory
@synthesize senderId, receiverId, messages, ID;

- (NSMutableArray *)sortedMessages {
    
    NSSortDescriptor *sortByDate = [NSSortDescriptor sortDescriptorWithKey:@"publishDate" ascending:YES];
    
    NSMutableArray *_messages = [messages mutableCopy];
    [_messages sortUsingDescriptors:@[sortByDate]];
    
    return _messages;
}

#pragma mark NSCoding Methods

- (void)encodeWithCoder:(NSCoder *)aCoder {
    
    [aCoder encodeObject:self.ID forKey:@"ID"];
    
    [aCoder encodeObject:self.senderId forKey:@"senderId"];
    [aCoder encodeObject:self.receiverId forKey:@"receiverId"];
    
    [aCoder encodeObject:self.messages forKey:@"messages"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    
    if (self = [self init]) {
        
        self.ID = [aDecoder decodeObjectForKey:@"ID"];
        
        self.senderId = [aDecoder decodeObjectForKey:@"senderId"];
        self.receiverId = [aDecoder decodeObjectForKey:@"receiverId"];
        
        self.messages = [aDecoder decodeObjectForKey:@"messages"];
    }
    
    return self;
}

#pragma mark Description

- (NSString *)description {
    
    return [NSString stringWithFormat:@"%@", self.messages];
}

#pragma mark Initialization

- (id)init {
    
    if (self = [super init]) {
        
    }
    
    return self;
}

- (id)initWithSenderId:(NSString *)_senderId andReceiverId:(NSString *)_receiverId andMessages:(NSMutableArray *)_messages {
    
    if (self = [self init]) {
        
        self.senderId = _senderId;
        self.receiverId = _receiverId;
        
        self.messages = _messages;
        
        self.ID = [NSString stringWithFormat:@"%@->%@", self.senderId, self.receiverId];
    }
    
    return self;
}

@end
