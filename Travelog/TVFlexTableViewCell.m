//
//  FlexTableViewCell.m
//  Trvlogue
//
//  Created by Rohan Kapur on 21/4/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import "TVFlexTableViewCell.h"

@implementation TVFlexTableViewCell

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

- (void)layoutSubviews {
    
    [super layoutSubviews];
    
    self.imageView.frame = CGRectMake(5, 4, 35, 35);
}

@end
