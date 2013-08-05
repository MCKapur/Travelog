//
//  TrvlogueFlightDetailViewController.h
//  Trvlogue
//
//  Created by Rohan Kapur on 23/3/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <Social/Social.h>

#import <QuartzCore/QuartzCore.h>

#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import "Annotation.h"

#import "NewsCell.h"

#import "WebViewController.h"

#import "UIGridView.h"
#import "UIGridViewDelegate.h"
#import "PersonCell.h"

#import "NSDate-Utilities.h"

typedef enum {
    
    kSegmentedControlPeople = 0,
    kSegmentedControlNews,
    kSegmentedControlPlaces,
    kSegmentedControlWeather,
    kSegmentedControlInfo,
    kSegmentedControlMap
    
} SegmentedControlSelected;

@interface TrvlogueFlightDetailViewController : UIViewController <MKMapViewDelegate, UINavigationControllerDelegate, UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate, UIGridViewDelegate>
{
    IBOutlet UIScrollView *infoScrollView;
    IBOutlet UIView *infoView;
    IBOutlet UISegmentedControl *infoSegControl;
        
    NSMutableArray *info;
        
    NSMutableArray *slideNames;
    int slideCount;
    
    int gridNumber;
    NSMutableDictionary *gridConvert;
}

@property (strong, nonatomic) IBOutlet UIGridView *peopleTableView;
@property (strong, nonatomic) IBOutlet UITableView *newsTableView;

@property (strong, nonatomic) IBOutlet UITableView *weatherTableView;
@property (strong, nonatomic) IBOutlet UILabel *weatherTimestamp;

- (IBAction)changedSegmentedControl:(UISegmentedControl *)sender;

@property (strong, nonatomic) IBOutlet MKMapView *travelMap;

@property (strong, nonatomic) IBOutlet UILabel *lastUpdatedLabel;

@property (nonatomic, strong) NSString *FlightID;

- (id)initWithTrvlogueFlightID:(NSString *)_FlightID;

- (IBAction)shareFlight;
- (IBAction)deleteFlight;

@end
