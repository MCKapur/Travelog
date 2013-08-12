//
//  MileTidbitsSwipeView.m
//  Trvlogue
//
//  Created by Rohan Kapur on 10/6/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import "TVSwipeBanner.h"

@implementation TVSwipeBanner
@synthesize tidbits, scrollView, page, mode;

- (void)setTidbits:(NSMutableArray *)_tidbits andMode:(TVSwipeBannerMode *)_mode {

    self.mode = _mode;
    
    if (self.mode == kTVSwipeBannerModeMileTidbits) {
        
        if (![_tidbits isEqualToArray:self.tidbits]) {
            
            self.tidbits = [TVMileTidbits getTidbitsFrom:[_tidbits[0] doubleValue]];
            
            for (UIView *subview in self.scrollView.subviews) {
                
                [subview removeFromSuperview];
            }
            
            self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width * self.tidbits.count, self.scrollView.frame.size.height);
            
            for (int i = 0; i <= self.tidbits.count - 1; i++) {
                
                UILabel *tidbitLabel = [[UILabel alloc] initWithFrame:CGRectMake(320 * i, 0, 320, 21)];
                tidbitLabel.backgroundColor = [UIColor clearColor];
                tidbitLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:15.0];
                tidbitLabel.textColor = [UIColor whiteColor];
                tidbitLabel.textAlignment = NSTextAlignmentCenter;
                [tidbitLabel setText:[NSString stringWithFormat:@"%@ %@", [TVMileTidbits formatTidbit:[self.tidbits[i][@"value"] doubleValue]], self.tidbits[i][@"name"]]];
                
                [self.scrollView addSubview:tidbitLabel];
            }
        }
    }
    else {
     
        self.tidbits = [[NSMutableArray alloc] init];
        
        for (UIView *subview in self.scrollView.subviews) {
            
            [subview removeGestureRecognizer:[subview gestureRecognizers][0]];
            [subview removeFromSuperview];
        }

        self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width * _tidbits.count, self.scrollView.frame.size.height);
        
        if (_tidbits.count) {
            
            for (int i = 0; i <= _tidbits.count - 1; i++) {
                
                [self addTravelInfoTidbit:_tidbits[i]];
            }
        }
    }
}

- (void)addTravelInfoTidbit:(NSDictionary *)_tidbit {
    
    BOOL isDrawn = NO;
    
    for (NSMutableDictionary *tidbit in self.tidbits) {
        
        if ([tidbit[@"ID"] isEqualToString:_tidbit[@"ID"]]) {
            
            isDrawn = YES;
        }
    }
    
    if (isDrawn) {
        
        for (UILabel *tidbitLabel in self.subviews) {

            if ([tidbitLabel.accessibilityIdentifier isEqualToString:_tidbit[@"ID"]]) {
               
                NSLog(@"change");
                
                [tidbitLabel setText:_tidbit[@"body"]];
            }
        }
    }
    else {
        
        self.backgroundColor = [UIColor colorWithRed:246.0f/255.0f green:246.0f/255.0f blue:246.0f/255.0f alpha:1.0];
        
        [self.tidbits addObject:_tidbit];
        
        self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width * self.tidbits.count, self.scrollView.frame.size.height);
        
        UILabel *tidbitLabel = [[UILabel alloc] initWithFrame:CGRectMake((320 * (self.tidbits.count - 1)) + 8, 0, 305, 50)];
        tidbitLabel.backgroundColor = [UIColor clearColor];
        tidbitLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:15.0];
        tidbitLabel.textColor = [UIColor darkGrayColor];
        tidbitLabel.textAlignment = NSTextAlignmentLeft;
        tidbitLabel.userInteractionEnabled = YES;
        tidbitLabel.numberOfLines = 2;
        [tidbitLabel setText:_tidbit[@"body"]];
        [tidbitLabel setAccessibilityIdentifier:_tidbit[@"ID"]];

        UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickedTravelTidbit:)];
        [recognizer setNumberOfTapsRequired:1];
        
        [tidbitLabel addGestureRecognizer:recognizer];

        [self.scrollView addSubview:tidbitLabel];
    }
}

- (void)clickedTravelTidbit:(UITapGestureRecognizer *)gr {
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"TidbitClicked" object:nil userInfo:@{@"ID": [[gr view] accessibilityIdentifier]}];
}

- (void)scroll {

    if (self.page < self.tidbits.count) {
        
        self.page++;
        
        [self.scrollView scrollRectToVisible:CGRectMake(self.page * 320, 0, 320, 21) animated:YES];
    }
    else {
        
        if (mode == kTVSwipeBannerModeMileTidbits) {
            
            [self.scrollView scrollRectToVisible:CGRectMake(0, 0, 320, 21) animated:YES];
            
            self.page = 0;
        }
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
            
            if (mode == kTVSwipeBannerModeMileTidbits) {
                
                timer = [NSTimer timerWithTimeInterval:2.5 target:self selector:@selector(scroll) userInfo:nil repeats:YES];
                [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
            }
        }
    }
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        
        self.backgroundColor = ((TVAppDelegate *)[[UIApplication sharedApplication] delegate]).backgroundColor;
        
        self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
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
