//
//  TrvlogueMessageHistory.h
//  Trvlogue
//
//  Created by Rohan Kapur on 18/6/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TVMessage.h"

@interface TVMessageHistory : NSObject <NSCoding>

@property (nonatomic, strong) NSString *ID;

@property (nonatomic, strong) NSString *senderId;
@property (nonatomic, strong) NSString *receiverId;

@property (nonatomic, strong) NSMutableArray *messages;

- (id)initWithSenderId:(NSString *)_senderId andReceiverId:(NSString *)_receiverId andMessages:(NSMutableArray *)_messages;

@end
