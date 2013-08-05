//
//  NotificationCell.m
//  Trvlogue
//
//  Created by Rohan Kapur on 9/6/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import "TVNotificationCell.h"

@implementation TVNotificationCell
@synthesize titleLabel;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
