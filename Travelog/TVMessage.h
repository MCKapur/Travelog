//
//  TVMessage.h
//  Trvlogue
//
//  Created by Rohan Kapur on 14/8/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TVMessage : NSObject <NSCoding>

@property (nonatomic, strong) NSString *ID;

@property (nonatomic, strong) NSString *body;

@property (nonatomic, strong) NSDate *publishDate;

@property (nonatomic, strong) NSString *senderId;
@property (nonatomic, strong) NSString *receiverId;

@property (nonatomic) BOOL receiverRead;

- (id)initWithBody:(NSString *)_body publishDate:(NSDate *)_publishDate senderId:(NSString *)_senderId andReceiverId:(NSString *)_receiverId;

@end
