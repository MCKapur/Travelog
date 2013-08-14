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

@property (nonatomic) BOOL recieverRead;

- (id)initWithBody:(NSString *)_body andPublishDate:(NSDate *)_publishDate;

@end
