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

@interface TVNotification : NSObject <NSCoding>

@property (nonatomic) NotificationType *type;

- (id)initWithType:(NotificationType *)_type;

@end