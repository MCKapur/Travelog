//
//  UnderlinedLabel.m
//  MileIndex
//
//  Created by Rohan Kapur on 31/10/12.
//  Copyright (c) 2012 UWCSEA. All rights reserved.
//

#import "TVUnderlinedLabel.h"

@implementation TVUnderlinedLabel

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        
    }
    
    return self;
}

- (void)drawRect:(CGRect)rect {
    
    // Get the size of the label
    CGSize dynamicSize = [self.text sizeWithFont:self.font constrainedToSize:CGSizeMake(99999, 99999) lineBreakMode:self.lineBreakMode];
    
    // Get the current graphics context
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Make it a while line 1.0 pixels wide
    CGContextSetStrokeColorWithColor(context, [self.textColor CGColor]);
    CGContextSetLineWidth(context, 0.7);
    
    // find the origin point
    CGPoint origin = CGPointMake(0, 0);
    
    // horizontal alignment depends on the alignment of the text
    if (self.textAlignment == NSTextAlignmentCenter)
        origin.x = (self.frame.size.width / 2) - (dynamicSize.width / 2);
    
    else if (self.textAlignment == NSTextAlignmentRight)
        origin.x = self.frame.size.width - dynamicSize.width;
    
    // vertical alignment is always middle/centre plus half the height of the text
    origin.y = (self.frame.size.height / 2.4) + (dynamicSize.height / 2.4);
    
    // Draw the line
    CGContextMoveToPoint(context, origin.x + 0.5, origin.y);
    CGContextAddLineToPoint(context, origin.x + dynamicSize.width, origin.y);
    CGContextStrokePath(context);

    [super drawRect: rect];
}


@end
