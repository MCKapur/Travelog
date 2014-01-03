//
//  TVMessageDetailViewController.h
//  Trvlogue
//
//  Created by Rohan Kapur on 18/8/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AMBubbleTableViewController.h"

#import "TVDatabase.h"

@interface TVMessageDetailViewController : AMBubbleTableViewController
{
    UIImage *myProfilePic;
    UIImage *hisProfilePic;
}

@property (nonatomic, strong) NSString *messageHistoryID;

- (id)initWithMessageHistoryID:(NSString *)_messageHistoryID;

@end
