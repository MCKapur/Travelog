//
//  FlightTableCell.h
//  Trvlogue
//
//  Created by Rohan Kapur on 14/3/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <QuartzCore/QuartzCore.h>

@interface TVFlightCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UILabel *flight;

@property (strong, nonatomic) IBOutlet UILabel *shortMiles;

@property (strong, nonatomic) IBOutlet UILabel *shortDate;

@property (strong, nonatomic) IBOutlet UIImageView *background;

@property (strong, nonatomic) IBOutlet UIImageView *gradient;

@end