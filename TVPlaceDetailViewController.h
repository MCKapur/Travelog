//
//  TVPlaceDetailViewController.h
//  Trvlogue
//
//  Created by Rohan Kapur on 15/8/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "TVGooglePlace.h"

@interface TVPlaceDetailViewController : UIViewController

@property (nonatomic, strong) TVGooglePlace *place;

- (id)initWithPlace:(TVGooglePlace *)_place;

@end
