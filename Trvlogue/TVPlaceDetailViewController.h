//
//  TVPlaceDetailViewController.h
//  Trvlogue
//
//  Created by Rohan Kapur on 15/8/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <MapKit/MapKit.h>

#import "TVGooglePlace.h"

#import "TVReviewCell.h"

#import "NSString+HTML.h"

@interface TVPlaceDetailViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, TVReviewCellDelegate>

@property (nonatomic, strong) TVGooglePlace *place;

@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *info;

@property (weak, nonatomic) IBOutlet UILabel *name;

- (id)initWithPlace:(TVGooglePlace *)_place;

- (IBAction)changedSegment:(UISegmentedControl *)sender;

+ (UIImage *)starImageForIndex:(int)index andRating:(float)rating;

@end
