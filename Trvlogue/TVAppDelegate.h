//
//  TrvlogueAppDelegate.h
//  Trvlogue
//
//  Created by Rohan Kapur on 11/3/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TVLoginViewController;

@class TVViewController;

@interface TVAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (nonatomic) int randomNumber;

@property (nonatomic, strong) UIColor *backgroundColor;

@property (strong, nonatomic) TVLoginViewController *loginViewController;

@property (strong, nonatomic) TVViewController *trvlogueViewController;

+ (UIColor *)generateRandomColor;

@end
