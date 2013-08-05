//
//  PersonCell.m
//  naivegrid
//
//  Created by Apirom Na Nakorn on 3/6/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "TVPersonCell.h"
#import <QuartzCore/QuartzCore.h> 

@implementation TVPersonCell

@synthesize profilePicture;
@synthesize name;

- (id)init {
	
    if (self = [super init]) {
		
        self.frame = CGRectMake(0, 0, 80, 80);
		
		[[NSBundle mainBundle] loadNibNamed:@"TVPersonCell" owner:self options:nil];
		
        [self addSubview:self.view];
        
        self.name.font = [UIFont fontWithName:@"Gotham Medium" size:13.0f];
		
        // Create the path (with only the top-left corner rounded)
        UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:self.profilePicture.bounds
                                                       byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight
                                                             cornerRadii:CGSizeMake(10.0, 10.0)];
        
        // Create the shape layer and set its path
        CAShapeLayer *maskLayer = [CAShapeLayer layer];
        maskLayer.frame = self.profilePicture.bounds;
        maskLayer.path = maskPath.CGPath;
        
        // Set the newly created shape layer as the mask for the image view's layer
        self.profilePicture.layer.mask = maskLayer;
	}
	
    return self;
	
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code.
}
*/

@end
