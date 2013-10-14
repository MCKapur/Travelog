//
//  TVPlaceDetailViewController.m
//  Trvlogue
//
//  Created by Rohan Kapur on 15/8/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import "TVPlaceDetailViewController.h"

#define HALF_STAR @"halfStar.png"
#define FULL_STAR @"fullStar.png"
#define EMPTY_STAR @"emptyStar.png"

@interface TVPlaceDetailViewController ()

@end

@implementation TVPlaceDetailViewController
@synthesize place, info;

- (IBAction)changedSegment:(UISegmentedControl *)sender {

    [self.tableView reloadData];
    [self.tableView setNeedsDisplay];
}

#pragma mark UITableView Methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    int retVal = 0;
    
    if (self.segmentedControl.selectedSegmentIndex == 0) {
        
        retVal = info.count;
    }
    else {
        
        retVal = self.place.reviews.count;
    }
    
    return retVal;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    NSString *INFO_CELL_ID = [NSString stringWithFormat:@"INFO_CELL_ID"];
    NSString *REVIEW_CELL_ID = [NSString stringWithFormat:@"REVIEW_CELL_ID"];
    
    NSString *CELL_ID = !self.segmentedControl.selectedSegmentIndex ? INFO_CELL_ID : REVIEW_CELL_ID;

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CELL_ID];
    
    if ([CELL_ID isEqualToString:INFO_CELL_ID]) {
        
        tableView.scrollEnabled = NO;
                
        if (!cell) {
            
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CELL_ID];
            
            cell.textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:14.0f];
            cell.textLabel.textColor = [UIColor grayColor];
            
            cell.detailTextLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16.0f];
            cell.detailTextLabel.textColor = [UIColor blackColor];
            
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
        }
        
        cell.textLabel.text = nil;
        cell.detailTextLabel.text = nil;
        
        cell.textLabel.text = [self.info[indexPath.row][@"ID"] lowercaseString];
        cell.detailTextLabel.text = self.info[indexPath.row][@"Object"];
    }
    else {

        tableView.scrollEnabled = YES;

        if (!cell) {

            NSArray *views = [[NSBundle mainBundle] loadNibNamed:@"TVReviewCell" owner:self options:nil];
            
            for (UIView *view in views) {
                
                if ([view isKindOfClass:[UITableViewCell class]])
                {
                    cell = (TVReviewCell *)view;
                }
            }
            
            ((TVReviewCell *) cell).delegate = self;
            ((TVReviewCell *) cell).authorName.text = [[place reviews][indexPath.row] authorName];
            ((TVReviewCell *) cell).reviewBodyTextView.text = [[[place reviews][indexPath.row] body] stringByConvertingHTMLToPlainText];
            ((TVReviewCell *) cell).authorURL = [[place reviews][indexPath.row] authorURL];
        
            int rating = 0;
            
            for (NSDictionary *aspect in [[place reviews][indexPath.row] aspects]) {
                
                rating += [aspect[@"rating"] intValue];
            }
            
            rating /= [[[place reviews][indexPath.row] aspects] count];
            
            rating /= 3;
            
            rating *= 5;
            
            [((TVReviewCell *) cell) setStars:rating];
            
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
    }
    
    return cell;
}

- (void)clickedAuthorButtonWithName:(NSString *)authorName andURL:(NSString *)authorURL {
    
    TVWebViewController *webViewController = [[TVWebViewController alloc] initWithLink:authorURL andTitle:authorName andMakeReadable:NO];
    
    [self.navigationController pushViewController:webViewController animated:YES];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (!self.segmentedControl.selectedSegmentIndex) {
        
        if ([info[indexPath.row][@"ID"] isEqualToString:@"Website"]) {
            
            TVWebViewController *webViewController = [[TVWebViewController alloc] initWithLink:info[indexPath.row][@"Object"] andTitle:self.place.name andMakeReadable:NO];
            
            [self.navigationController pushViewController:webViewController animated:YES];
        }
        else if ([info[indexPath.row][@"ID"] isEqualToString:@"Address"]) {
            
            MKPlacemark *placemark = [[MKPlacemark alloc] initWithCoordinate:self.place.coordinate addressDictionary:nil];
            
            MKMapItem *mapItem = [[MKMapItem alloc] initWithPlacemark:placemark];
            [mapItem setName:place.name];
            [mapItem setPhoneNumber:place.phoneNumber];
            [mapItem setUrl:[NSURL URLWithString:place.website]];
            
            [mapItem openInMapsWithLaunchOptions:nil];
        }
        else if ([info[indexPath.row][@"ID"] isEqualToString:@"Phone Number"]) {
            
            NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"tel://%@", info[indexPath.row][@"Object"]]];
            
            [[UIApplication sharedApplication] openURL:URL];
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    float retVal = 0.0f;
    
    if (!self.segmentedControl.selectedSegmentIndex) {
        
        retVal = 67.0f;
    }
    else {
        
        retVal = 99.0f;
    }
    
    return retVal;
}

#pragma mark MKMapView Methods

- (void)centerMap {
    
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(self.place.coordinate, 500, 500);
    [self.mapView setRegion:region animated:NO];
}

- (void)drawAnnotations {
    
    MKPointAnnotation *annotationPoint = [[MKPointAnnotation alloc] init];
    
    annotationPoint.coordinate = self.place.coordinate;
    annotationPoint.title = self.place.name;
    
    [self.mapView addAnnotation:annotationPoint];
}

#pragma mark Initialization

- (id)init {
    
    if (self = [super init]) {
        
        self.info = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void)setPlace:(TVGooglePlace *)_place {
    
    if (![self.place isEqual:_place]) {
        
        [self.info removeAllObjects];
        
        place = _place;
        
        if (self.place.website)[info addObject:@{@"ID": @"Website", @"Object": self.place.website}];
        if (self.place.phoneNumber)[info addObject:@{@"ID": @"Phone Number", @"Object": self.place.phoneNumber}];
        if (self.place.address)[info addObject:@{@"ID": @"Address", @"Object": self.place.address}];
    }
}

- (id)initWithPlace:(TVGooglePlace *)_place andDelegate:(id<TVPlaceDetailViewControllerDelegate>)delegate {
    
    if (self = [self init]) {
        
        self.place = _place;
        self.delegate = delegate;
        NSLog(@"%@", self.delegate);
    }
    
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    [self.tableView reloadData]; 
    [self.tableView setNeedsDisplay];
    
    for (int i = 1; i <= 5; i++) {
        
        if (place.rating) {
            
            [((UIImageView *)[self.view viewWithTag:i]) setImage:[TVPlaceDetailViewController starImageForIndex:i andRating:self.place.rating]];
        }
        else {
            
            [((UIImageView *)[self.view viewWithTag:i]) removeFromSuperview];
        }
    }
    
    self.name.text = self.place.name;

    if (!self.place.reviews.count) {
        
        [self.segmentedControl removeSegmentAtIndex:1 animated:NO];
    }
    
    UIBarButtonItem *submitFlight = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(savePlace)];
    self.navigationItem.rightBarButtonItem = submitFlight;
    
    self.navigationItem.title = self.place.name;
    
    [self centerMap];
    [self drawAnnotations];
}

+ (UIImage *)starImageForIndex:(int)index andRating:(float)rating {
    
    UIImage *retVal = [UIImage imageNamed:EMPTY_STAR];
    
    if (index == 1) {
        
        if (rating) {
            
            if (rating <= 0.6f >= 0.3f) {
                
                retVal = [UIImage imageNamed:HALF_STAR];
            }
            else {
                
                retVal = [UIImage imageNamed:FULL_STAR];
            }
        }
    }
    else if (index == 2) {
        
        if (rating <= 1.6f >= 1.3f) {
            
            retVal = [UIImage imageNamed:HALF_STAR];
        }
        else if (rating > 1.6f) {
            
            retVal = [UIImage imageNamed:FULL_STAR];
        }
    }
    else if (index == 3) {
        
        if (rating <= 2.6f >= 2.3f) {
            
            retVal = [UIImage imageNamed:HALF_STAR];
        }
        else if (rating > 2.6f) {
            
            retVal = [UIImage imageNamed:FULL_STAR];
        }
    }
    else if (index == 4) {
        
        if (rating <= 3.6f >= 3.3f) {
            
            retVal = [UIImage imageNamed:HALF_STAR];
        }
        else if (rating > 3.6f) {
            
            retVal = [UIImage imageNamed:FULL_STAR];
        }
    }
    else if (index == 5) {
        
        if (rating <= 4.6f >= 4.3f) {
            
            retVal = [UIImage imageNamed:HALF_STAR];
        }
        else if (rating > 4.6f) {
            
            retVal = [UIImage imageNamed:FULL_STAR];
        }
    }
    
    return retVal;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)savePlace {
    
    [self.delegate savedPlace:self.place];
    
    [TVNotificationSignifier signifyNotification:@"Saved place" forDuration:3];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
