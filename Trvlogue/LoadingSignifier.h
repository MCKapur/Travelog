//
//  LoadingSignifier.h
//  Trvlogue
//
//  Created by Rohan Kapur on 20/3/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MTStatusBarOverlay.h"

@interface LoadingSignifier : NSObject <MTStatusBarOverlayDelegate>

+ (void)signifyLoading:(NSString *)signiferString duration: (int)duration;
+ (void)hideLoadingSignifier;

@end
