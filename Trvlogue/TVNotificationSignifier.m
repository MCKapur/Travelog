//
//  NotificationSignifier.m
//  Trvlogue
//
//  Created by Rohan Kapur on 3/4/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import "TVNotificationSignifier.h"

@implementation TVNotificationSignifier

+ (void)signifyNotification:(NSString *)notification forDuration: (int)duration {
    
    if ([NSThread isMainThread]) {
        
        [MTStatusBarOverlay sharedInstance].animation = MTStatusBarOverlayAnimationFallDown;
        [MTStatusBarOverlay sharedInstance].detailViewMode = MTDetailViewModeHistory;
        
        [[MTStatusBarOverlay sharedInstance] postFinishMessage:notification duration: duration];
        
        [[MTStatusBarOverlay sharedInstance] setHidden:NO];
    }
    else {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [TVNotificationSignifier signifyNotification:notification forDuration: duration];
        });
    }
}

@end
