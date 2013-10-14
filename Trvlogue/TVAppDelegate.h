//
//  TrvlogueAppDelegate.h
//  Trvlogue
//
//  Created by Rohan Kapur on 11/3/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "CustomBadge.h"

@class TVLoginViewController;

@class TVFlightsViewController;

@interface TVAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (nonatomic) int randomNumber;

@property (nonatomic, strong) UIColor *swipeColor;

- (void)updateNotifications;
- (void)hideNotifications;
- (void)showNotifications;

- (void)didLogIn;
- (void)didLogOut;

@end
