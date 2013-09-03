//
//  TVMessageDetailViewController.h
//  Trvlogue
//
//  Created by Rohan Kapur on 18/8/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "JSMessagesTableViewController/JSMessagesViewController.h"

#import "TVDatabase.h"

@interface TVMessageDetailViewController : JSMessagesViewController <JSMessagesViewDataSource, JSMessagesViewDelegate>

@property (nonatomic, strong) NSString *messageHistoryID;

- (id)initWithMessageHistoryID:(NSString *)_messageHistoryID;

@end
