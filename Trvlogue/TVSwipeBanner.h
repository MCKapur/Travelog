//
//  MileTidbitsSwipeView.h
//  Trvlogue
//
//  Created by Rohan Kapur on 10/6/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "TVMileTidbits.h"

#import "TVAppDelegate.h"

#import "UIColor+MLPFlatColors/UIColor+MLPFlatColors.h"

typedef enum {
    
    kTVSwipeBannerModeMileTidbits = 0,
    kTVSwipeBannerTravelInfo
    
} TVSwipeBannerMode;

@interface TVSwipeBanner : UIView <UIScrollViewDelegate>
{
    NSTimer *timer;
}

- (void)setTidbits:(NSMutableArray *)_tidbits andMode:(TVSwipeBannerMode *)mode;
- (void)addTravelInfoTidbit:(NSDictionary *)tidbit;

- (void)scroll;

@property (nonatomic) TVSwipeBannerMode *mode;

@property (nonatomic) int page;

@property (strong, nonatomic) UIScrollView *scrollView;

@property (nonatomic, strong) NSMutableArray *tidbits;

@end
