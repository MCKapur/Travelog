//
//  TrvlogueConnection.m
//  Trvlogue
//
//  Created by Rohan Kapur on 30/6/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import "TVConnection.h"

@implementation TVConnection
@synthesize senderId, receiverId, status;

- (void)encodeWithCoder:(NSCoder *)aCoder {
    
    [aCoder encodeObject:self.senderId forKey:@"senderId"];
    [aCoder encodeObject:self.receiverId forKey:@"receiverId"];
    
    [aCoder encodeInt:(int)self.status forKey:@"status"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    
    if (self = [super init]) {
        
        self.senderId = [aDecoder decodeObjectForKey:@"senderId"];
        self.receiverId = [aDecoder decodeObjectForKey:@"receiverId"];
        
        self.status = (ConnectRequestStatus *)[aDecoder decodeIntForKey:@"status"];
    }
    
    return self;
}

- (id)init {
    
    if (self = [super init]) {
    }
    
    return self;
}

- (id)initWithSenderId:(NSString *)_senderId receiverId:(NSString *)_receiverId andStatus:(ConnectRequestStatus *)_status {
    
    if (self = [self init]) {
        
        self.senderId = _senderId;
        self.receiverId = _receiverId;
        
        self.status = _status;
    }
    
    return self;
}

- (NSString *)description {
    
    return [NSString stringWithFormat:@"I %@ and the status is %@", [[[TVDatabase currentAccount] userId] isEqualToString:self.senderId] ? [NSString stringWithFormat:@"sent to %@", self.receiverId] : [NSString stringWithFormat:@"received from %@", self.senderId], (int)self.status == kConnectRequestPending ? @"pending" : @"accepted"];
}

@end
