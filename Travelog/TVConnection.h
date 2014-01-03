//
//  TrvlogueConnection.h
//  Trvlogue
//
//  Created by Rohan Kapur on 30/6/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    
    kConnectRequestPending = 0,
    kConnectRequestAccepted
    
} ConnectRequestStatus;

@interface TVConnection : NSObject <NSCoding>

@property (nonatomic, strong) NSString *senderId;
@property (nonatomic, strong) NSString *receiverId;

@property (nonatomic) ConnectRequestStatus *status;

- (id)initWithSenderId:(NSString *)_senderId receiverId:(NSString *)_receiverId andStatus:(ConnectRequestStatus *)_status;

@end
