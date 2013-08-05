//
//  MileTidbitsSwipeView.h
//  Trvlogue
//
//  Created by Rohan Kapur on 10/6/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MileTidbits.h"

#import "TrvlogueAppDelegate.h"

@interface MileTidbitsSwipeView : UIView <UIScrollViewDelegate>
{
    NSTimer *timer;
}

- (void)updateWithMiles:(double)miles;

- (void)scroll;

@property (nonatomic) int page;

@property (strong, nonatomic) UIScrollView *scrollView;

@property (nonatomic, strong) NSMutableArray *mileTidbits;

@end
