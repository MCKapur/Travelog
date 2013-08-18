//
//  TVReviewCell.m
//  Trvlogue
//
//  Created by Rohan Kapur on 17/8/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import "TVReviewCell.h"

@implementation TVReviewCell
@synthesize authorURL;

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

- (IBAction)clickedAuthor {

    [self.delegate clickedAuthorButtonWithName:self.authorName.text andURL:self.authorURL];
}

- (void)setStars:(float)rating {

    for (int i = 1; i <= 5; i++) {
        
        if (rating) {
            
            [((UIImageView *)[self viewWithTag:i]) setImage:[TVPlaceDetailViewController starImageForIndex:i andRating:rating]];
        }
        else {
            
            [((UIImageView *)[self viewWithTag:i]) removeFromSuperview];
        }
    }
}

@end
