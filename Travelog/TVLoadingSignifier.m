//
//  LoadingSignifier.m
//  Trvlogue
//
//  Created by Rohan Kapur on 20/3/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import "TVLoadingSignifier.h"

@implementation TVLoadingSignifier

+ (void)signifyLoading:(NSString *)signiferString duration: (int)duration {

    if ([NSThread isMainThread]) {

        [MTStatusBarOverlay sharedInstance].animation = MTStatusBarOverlayAnimationFallDown;
        [MTStatusBarOverlay sharedInstance].detailViewMode = MTDetailViewModeHistory;
        
        [MTStatusBarOverlay sharedInstance].progress = 0.0;
        [[MTStatusBarOverlay sharedInstance] postImmediateMessage:signiferString duration:duration animated:YES];
        [MTStatusBarOverlay sharedInstance].progress = 1.0;
        
        [[MTStatusBarOverlay sharedInstance] setHidden: NO];
    }
    else {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self signifyLoading:signiferString duration: duration];
        });
    }
}

+ (void)hideLoadingSignifier {
    
    if ([NSThread isMainThread]) {

        [[MTStatusBarOverlay sharedInstance] hide];
    }
    else {
        
        dispatch_async(dispatch_get_main_queue(), ^{

            [TVLoadingSignifier hideLoadingSignifier];
        });
    }
}

@end
