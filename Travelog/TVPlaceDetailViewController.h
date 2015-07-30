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

#import "CustomIOS7AlertView.h"

@protocol TVPlaceDetailViewControllerDelegate <NSObject>

- (void)savedPlace:(TVGooglePlace *)place;

@end

@interface TVPlaceDetailViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, TVReviewCellDelegate, UITextViewDelegate> {
    
    NSMutableDictionary *textViews;
}

@property (nonatomic, strong) TVGooglePlace *place;

@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *info;

@property (weak, nonatomic) IBOutlet UILabel *name;

@property (weak, nonatomic) id<TVPlaceDetailViewControllerDelegate> delegate;

- (id)initWithPlace:(TVGooglePlace *)_place andDelegate:(id<TVPlaceDetailViewControllerDelegate>)delegate;

- (IBAction)changedSegment:(UISegmentedControl *)sender;

+ (UIImage *)starImageForIndex:(NSInteger)index andRating:(float)rating;

@end
