//
//  GIFBackground.m
//  Trvlogue
//
//  Created by Rohan Kapur on 16/3/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import "GIFBackground.h"

#import "UIImage+animatedGIF.h"

#import "TrvlogueAppDelegate.h"

@implementation GIFBackground

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    
    return self;
}

- (void)animateGIF {
        
    NSURL *url = [[NSBundle mainBundle] URLForResource:[NSString stringWithFormat:@"%i", [((TrvlogueAppDelegate *)[UIApplication sharedApplication].delegate) randomNumber]] withExtension:@"gif"];
    
    self.image = [UIImage animatedImageWithAnimatedGIFData:[NSData dataWithContentsOfURL:url]];
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.

- (void)drawRect:(CGRect)rect
{
    // Drawing code
    
}

@end
