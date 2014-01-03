//
//  TrvlogueNotification.h
//  Trvlogue
//
//  Created by Rohan Kapur on 9/6/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    
    kNotificationTypeConnectionRequest = 0,
    kNotificationTypeUnreadMessages
    
} NotificationType;

#define PENDING_CONNECTION_REQUEST @"PENDING_CONNECTION_REQUEST"
#define UNREAD_MESSAGE @"UNREAD_MESSAGE"

@interface TVNotification : NSObject <NSCoding>

@property (nonatomic) NotificationType *type;
@property (nonatomic, strong) NSString *ID;

- (id)initWithType:(NotificationType *)_type withUserId:(NSString *)userId;

@end