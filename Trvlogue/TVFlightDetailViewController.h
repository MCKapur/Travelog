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
#import "TVAnnotation.h"

#import "TVNewsCell.h"

#import "TVWebViewController.h"

#import "UIGridView.h"
#import "UIGridViewDelegate.h"
#import "TVPersonCell.h"

#import "NSDate-Utilities.h"

#import "TVSwipeBanner.h"

typedef enum {
    
    kSegmentedControlPeople = 0,
    kSegmentedControlNews,
    kSegmentedControlPlaces,
    kSegmentedControlWeather,
    kSegmentedControlInfo,
    kSegmentedControlMap
    
} SegmentedControlSelected;

@interface TVFlightDetailViewController : UIViewController <MKMapViewDelegate, UINavigationControllerDelegate, UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate, UIGridViewDelegate>
{
    __weak IBOutlet UIScrollView *infoScrollView;
    __weak IBOutlet UIView *infoView;
    __weak IBOutlet UISegmentedControl *infoSegControl;
        
    NSMutableDictionary *info;
        
    NSMutableArray *slideNames;
    int slideCount;
    
    int gridNumber;
    NSMutableDictionary *gridConvert;
}

@property (strong, nonatomic) IBOutlet UIGridView *peopleTableView;
@property (weak, nonatomic) IBOutlet UITableView *newsTableView;

@property (weak, nonatomic) IBOutlet UITableView *weatherTableView;
@property (weak, nonatomic) IBOutlet UILabel *weatherTimestamp;

@property (strong, nonatomic) TVSwipeBanner *travelInfoBanner;

@property (nonatomic, strong) NSString *FlightID;

- (id)initWithTrvlogueFlightID:(NSString *)_FlightID;

- (IBAction)changedSegmentedControl:(UISegmentedControl *)sender;

- (IBAction)shareFlight;
- (IBAction)deleteFlight;

@end
