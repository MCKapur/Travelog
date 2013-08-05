//
//  TrvlogueAppDelegate.h
//  Trvlogue
//
//  Created by Rohan Kapur on 11/3/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TrvlogueLoginViewController;

@class TrvlogueViewController;

@interface TrvlogueAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (nonatomic) int randomNumber;

@property (nonatomic, strong) UIColor *backgroundColor;

@property (strong, nonatomic) TrvlogueLoginViewController *loginViewController;

@property (strong, nonatomic) TrvlogueViewController *trvlogueViewController;

+ (UIColor *)generateRandomColor;

@end
