//
//  MileTidbitsSwipeView.m
//  Trvlogue
//
//  Created by Rohan Kapur on 10/6/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import "MileTidbitsSwipeView.h"

@implementation MileTidbitsSwipeView
@synthesize mileTidbits, scrollView, page;

- (void)updateWithMiles:(double)miles {

    self.mileTidbits = [MileTidbits getTidbitsFrom:miles];
    
    for (UIView *subview in self.scrollView.subviews) {
        
        [subview removeFromSuperview];
    }
    
    self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width * self.mileTidbits.count, self.scrollView.frame.size.height);
    
    for (int i = 0; i <= self.mileTidbits.count - 1; i++) {        
        
        UILabel *tidbitLabel = [[UILabel alloc] initWithFrame:CGRectMake(320 * i, 0, 320, 21)];
        tidbitLabel.backgroundColor = [UIColor clearColor];
        tidbitLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:15.0];
        tidbitLabel.textColor = [UIColor whiteColor];
        tidbitLabel.textAlignment = NSTextAlignmentCenter;
        [tidbitLabel setText:[NSString stringWithFormat:@"%@ %@", [MileTidbits formatTidbit:[self.mileTidbits[i][@"value"] doubleValue]], self.mileTidbits[i][@"name"]]];

        [self.scrollView addSubview:tidbitLabel];
    }
}

- (void)scroll {

    if (self.page < self.mileTidbits.count) {
        
        self.page++;

        [self.scrollView scrollRectToVisible:CGRectMake(self.page * 320, 0, 320, 21) animated:YES];
    }
    else {
        
        [self.scrollView scrollRectToVisible:CGRectMake(0, 0, 320, 21) animated:YES];
        
        self.page = 0;
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)_scrollView {

    if (_scrollView.dragging) {
    
        CGFloat pageWidth = _scrollView.frame.size.width;
        int _page = floor((_scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
        
        if ((_page) && (_page != self.page)) {
            
            [timer invalidate];
            timer = nil;

            self.page = _page;
            
            timer = [NSTimer timerWithTimeInterval:2.5 target:self selector:@selector(scroll) userInfo:nil repeats:YES];
            [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
        }
    }
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        
        self.backgroundColor = ((TrvlogueAppDelegate *)[[UIApplication sharedApplication] delegate]).backgroundColor;
        
        self.scrollView = [[UIScrollView alloc] initWithFrame:frame];
        self.scrollView.backgroundColor = [UIColor clearColor];
        self.scrollView.pagingEnabled = YES;
        self.scrollView.showsHorizontalScrollIndicator = NO;
        self.scrollView.showsVerticalScrollIndicator = NO;
        self.scrollView.scrollsToTop = NO;
        self.scrollView.delegate = self;
        self.scrollView.bounces = NO;
        
        [self addSubview:self.scrollView];

        self.page = 0;
                
        timer = [NSTimer timerWithTimeInterval:2.5 target:self selector:@selector(scroll) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
    }
    
    return self;
}

- (void)dealloc {
    
    [timer invalidate];
}

@end
