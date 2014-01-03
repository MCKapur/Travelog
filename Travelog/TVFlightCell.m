//
//  FlightTableCell.m
//  Trvlogue
//
//  Created by Rohan Kapur on 14/3/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import "TVFlightCell.h"

#import <QuartzCore/QuartzCore.h>

@implementation TVFlightCell
@synthesize background;

- (id)init {
    
    self = [super init];
    
    if (self) {
    }
    
    return self;
}

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
