//
//  TrvlogueAppDelegate.h
//  Trvlogue
//
//  Created by Rohan Kapur on 11/3/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "CustomBadge.h"

#import "TVAccount.h"

#import "Helpshift.h"

@class TVLoginViewController;

@class TVFlightsViewController;

@class TVAccount;

@interface TVAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (nonatomic) NSInteger randomNumber;

@property (nonatomic, strong) UIColor *swipeColor;

@property (strong, nonatomic) NSMutableArray *emails;
@property (strong, nonatomic) NSMutableArray *cachedAccounts;
@property (strong, nonatomic) TVAccount *loggedInAccount;

- (void)didLogIn;
- (void)didLogOut;

@end
