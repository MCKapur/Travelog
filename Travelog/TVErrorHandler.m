//
//  ErrorHandler.m
//  Trvlogue
//
//  Created by Rohan Kapur on 20/3/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import "TVErrorHandler.h"

@implementation TVErrorHandler

+ (void)handleError:(NSError *)error {

    if ([NSThread isMainThread]) {
        
        [MTStatusBarOverlay sharedInstance].animation = MTStatusBarOverlayAnimationFallDown;
        [MTStatusBarOverlay sharedInstance].detailViewMode = MTDetailViewModeHistory;
        
        [[MTStatusBarOverlay sharedInstance] postErrorMessage:error.localizedDescription duration:2.0 animated: YES];
        
        [[MTStatusBarOverlay sharedInstance] setHidden: NO];
    }
    else {
        
        dispatch_async(dispatch_get_main_queue(), ^{
           
            [TVErrorHandler handleError:error];
        });
    }
}

+ (void)generalError {
    
    [TVErrorHandler handleError: [NSError errorWithDomain:@"Couldn't talk to our database" code:200 userInfo: @{NSLocalizedDescriptionKey:  @"Couldn't talk to our database"}]];
}

@end
