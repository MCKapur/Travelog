
//  TrvlogueViewController.m
//  Trvlogue
//
//  Created by Rohan Kapur on 11/3/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import "TVFlightsViewController.h"

@interface NSMutableArray (HasAnEqualObject)

- (BOOL)hasACollectiveNotification:(TVNotification *)notification1;

@end

@implementation NSMutableArray (HasAnEqualObject)

- (BOOL)hasACollectiveNotification:(TVNotification *)notification1 {
    
    BOOL duplicate = NO;
    
    for (TVNotification *notification2 in self) {
        
        if (notification1.type == notification2.type) {
            
            duplicate = YES;
        }
    }
    
    return duplicate;
}

@end

@interface NSMutableArray (CollectiveNotifications)

- (NSMutableArray *)collectiveNotifications;

@end

@implementation NSMutableArray (CollectiveNotifications)

- (NSMutableArray *)collectiveNotifications {
    
    NSMutableArray *collectiveNotifications = [[NSMutableArray alloc] init];
    
    for (TVNotification *notification in self) {
        
        if (![collectiveNotifications hasACollectiveNotification:notification]) {
            
            [collectiveNotifications addObject:notification];
        }
    }
    
    return collectiveNotifications;
}

@end

@implementation TVFlightsViewController
@synthesize shouldRefresh, mileTidbitsSwipeView;

- (void)refreshedFlights {
    
    [self updateFlights];
    [self updateMilesLabel];
}

#pragma mark UITableView Methods

- (void)updateFlights {
    
    [self.flightsTable reloadData];
    [self.flightsTable setNeedsDisplay];
}

- (void)refreshAccount:(UIRefreshControl *)refreshControl {
    
    if (shouldRefresh) {
        
        [refreshControl beginRefreshing];
        [self.flightsTable setContentOffset:CGPointMake(0, -refreshControl.frame.size.height) animated:YES];
        
        [TVDatabase downloadFlightsWithObjectIds:[NSArray arrayWithObject:[[TVDatabase currentAccount] userId]] withCompletionHandler:^(NSError *error, NSMutableArray *flights) {
            
            TVAccount *account = [TVDatabase currentAccount];
            [[account person] setFlights:[NSKeyedUnarchiver unarchiveObjectWithData:flights[0][@"flights"]]];
            
            [TVDatabase updateMyCache:account];
            
            [self updateFlights];
            [self updateMilesLabel];
            
            if (refreshControl) {
                
                [refreshControl endRefreshing];
            }
        }];
    }
}

- (NSString *)getLastUpdatedStringFromDate:(NSDate *)lastUpdated {
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"hh:mm a"];
    
    NSLocale *twelveHourLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    [dateFormatter setLocale:twelveHourLocale];
    
    NSDateFormatter *dayFormatter = [[NSDateFormatter alloc] init];
    [dayFormatter setDateFormat:@"EEEE"];
    
    NSString *formattedLastUpdated;
    
    if ([lastUpdated isToday]) {
        
        formattedLastUpdated = [NSString stringWithFormat:@"today at %@", [dateFormatter stringFromDate:lastUpdated]];
    }
    else if ([lastUpdated isYesterday]) {
        
        formattedLastUpdated = [NSString stringWithFormat:@"yesterday at %@", [dateFormatter stringFromDate:lastUpdated]];
    }
    else if ([lastUpdated isThisWeek] && ![lastUpdated isToday] && ![lastUpdated isYesterday]) {
        
        formattedLastUpdated = [NSString stringWithFormat:@"%@ at %@", [dayFormatter stringFromDate:lastUpdated],  [dateFormatter stringFromDate:lastUpdated]];
    }
    else if ([lastUpdated isLastWeek]) {
        
        formattedLastUpdated = [NSString stringWithFormat:@"last week %@ at %@", [dayFormatter stringFromDate:lastUpdated], [dateFormatter stringFromDate:lastUpdated]];
    }
    else if ([lastUpdated daysBeforeDate:[NSDate date]] > 7) {
        
        [dateFormatter setDateStyle:NSDateFormatterShortStyle];
        
        formattedLastUpdated = [NSString stringWithFormat:@"%@ at %@", [dateFormatter stringFromDate:lastUpdated],  [dateFormatter stringFromDate:lastUpdated]];
    }
    
    return [NSString stringWithFormat:@"Last updated %@", formattedLastUpdated];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    int retVal = 0;
    
    if (tableView == self.flightsTable) {
        
        retVal = [[[[[[TVDatabase currentAccount] person] flights] mutableCopy] sortedByDate] count];
    }
    
    return retVal;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    int retVal = 0;
    
    if (tableView == self.flightsTable) {
        
        retVal = 65.0f;
    }
    else {
        
        retVal = 27.0f;
    }
    
    return retVal;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (tableView == self.flightsTable) {
        
        [detailView setFlightID:[((TVFlight *)[[[[[TVDatabase currentAccount] person] flights] mutableCopy] sortedByDate][indexPath.row]) ID]];
        
        [self.navigationController pushViewController:detailView animated:YES];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *FlightCell = @"FlightTableCell";
    
    NSString *CellIdentifier = nil;
    
    if (tableView == self.flightsTable) {
        
        CellIdentifier = FlightCell;
    }
    
    tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if ([CellIdentifier isEqualToString:FlightCell]) {
        
        if (!cell) {
            
            NSArray *views = [[NSBundle mainBundle] loadNibNamed:@"TVFlightCell" owner:self options:nil];
            
            for (UIView *view in views) {
                
                if ([view isKindOfClass:[UITableViewCell class]])
                {
                    cell = (TVFlightCell *)view;
                }
            }
            
            ((TVFlightCell *)cell).gradient.layer.masksToBounds = YES;
            ((TVFlightCell *)cell).gradient.layer.cornerRadius = 3.0f;
                        
            [(TVFlightCell *)cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        }
        
        TVFlight *flight = [[[[[TVDatabase currentAccount] person] flights] mutableCopy] sortedByDate][indexPath.row];
        
        ((TVFlightCell *)cell).flight.text = [NSString stringWithFormat:@"%@ to %@", flight.originCity, flight.destinationCity];
        
        ((TVFlightCell *)cell).shortMiles.text = [self generateShortcuttedMiles:[flight miles]];
        
        ((TVFlightCell *)cell).shortDate.text = [self generateShortcuttedDates:[flight date]];
        
        ((TVFlightCell *)cell).flight.font = [UIFont fontWithName:@"Gotham Book" size:15.0f];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    TVAccount *account = [TVDatabase currentAccount];
    [[account person] deleteFlight:[[[account person] flights] sortedByDate][indexPath.row]];
    
    [TVLoadingSignifier signifyLoading:@"Deleting flight" duration:-1];
    
    [TVDatabase updateMyAccount:account immediatelyCache:NO withCompletionHandler:^(BOOL succeeded, NSError *error, NSString *callCode) {
        
        if (!error && succeeded) {
            
            [TVNotificationSignifier signifyNotification:@"Successfully deleted flight" forDuration:3];
        }
        else {
            
            [TVErrorHandler handleError:error];
        }
    }];
    
    [self.flightsTable beginUpdates];
    [self.flightsTable deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForItem:indexPath.row inSection:0]] withRowAnimation:UITableViewRowAnimationBottom];
    [self.flightsTable endUpdates];
    
    [self updateMilesLabel];
}

#pragma mark Operational Methods

- (NSString *)generateShortcuttedDates:(NSDate *)date {
    
    return [TVConversions convertDateToString:date withFormat:DAY_MONTH];
}

- (NSString *)generateShortcuttedMiles:(double)miles {
    
    NSString *toString = [NSString stringWithFormat:@"%i", (int)(miles + 0.5)];
    
    NSString *retVal;
    
    switch (toString.length) {
            
        case 1: {
            
            // e.g. 1.8 = 2
            retVal = toString;
        }
            break;
            
        case 2: {
            
            // e.g. 12.3 = 12
            retVal = toString;
        }
            
        case 3: {
            
            // e.g. 142.32 = 142 = .14k
            // e.g. 200 = .2k
            
            NSString *trail = [toString substringToIndex:2];
            trail = [trail stringByReplacingOccurrencesOfString:@"0" withString:@""];
            
            retVal = [NSString stringWithFormat:@"0.%@k", trail];
        }
            break;
            
        case 4: {
            
            // e.g. 1492.96 = 1493 = 1.5k
            // e.g. 9999 = 9.9k
            // e.g. 2011 = 2.0k
            
            int backToInt = toString.intValue;
            backToInt = 10 * floor((backToInt/10)+0.5);
            
            toString = [[NSString alloc] initWithFormat:@"%i", backToInt];
            toString = [toString stringByReplacingOccurrencesOfString:@"0" withString:@""];
            
            retVal = [[NSString alloc] initWithFormat:@"%@.%@k", [toString substringToIndex:1], [toString substringFromIndex:1]];
        }
            break;
            
        case 5: {
            
            // e.g. 11021.93 = 11000 = 11k
            // e.g. 19493 = 19500 = 19.5k;
            // e.g. 10100 = 10.1k;
            // e.g. 10000 = 10k
            
            int backToInt = toString.intValue;
            backToInt = 100 * floor((backToInt/100) + 0.5);
            
            toString = [[NSString alloc] initWithFormat:@"%i", backToInt];
            
            NSString *decimal = [toString substringFromIndex:2];
            
            if ([[NSString stringWithFormat:@"%c", [decimal characterAtIndex:1]] intValue] >= 5) {
                
                decimal = [NSString stringWithFormat:@"%i", [[decimal substringToIndex:1] intValue] + 1];
            }
            else {
                
                decimal = [decimal substringToIndex:1];
            }
            
            toString = [[NSString alloc] initWithFormat:@"%@.%@k", [toString substringToIndex:2], decimal];
            
            if ([toString hasSuffix:@".0"]) {
                
                [toString stringByReplacingOccurrencesOfString:@".0" withString:@""];
            }
            
            retVal = toString;
            
        }
            break;
            
        default: {
            
            retVal = @"U";
        }
            break;
    }
    
    return retVal;
}

#pragma mark Miles

- (void)shareMiles {
    
    NSArray *activityItems = @[[NSString stringWithFormat:@"I've clocked %@ flight miles so far! via Travelog (www.travelogapp.com)", [[TVMileTidbits formatTidbit:[[[TVDatabase currentAccount] person] miles]] stringByReplacingOccurrencesOfString:@" " withString:@""]]];
    
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
    activityViewController.excludedActivityTypes = @[UIActivityTypePostToWeibo, UIActivityTypeAssignToContact];
    
    [self presentViewController:activityViewController animated:YES completion:NULL];
}

- (NSMutableArray *)fetchMileTidbits {
    
    return [[[TVDatabase currentAccount] person] mileTidbits];
}

- (void)updateMilesLabel {
   
    double miles = 0.0f;
    
    for (TVFlight *flight in [[[TVDatabase currentAccount] person] flights]) {
        
        miles += flight.miles;
    }
    
    [self.mileTidbitsSwipeView setTidbits:[NSMutableArray arrayWithObject:@(miles)] andMode:kTVSwipeBannerModeMileTidbits];
}

#pragma mark Flight Recording + Delegate

- (void)recordAFlight {
    
    TVFlightRecorderViewController *flightRecorder = [[TVFlightRecorderViewController alloc] init];
    [self.navigationController pushViewController:flightRecorder animated:YES];
}

#pragma mark UI Handling

- (void)UIBuffer {
    
    // Do some Funky, Dirty, Native stuff here. JK
    
    self.mileTidbitsSwipeView = [[TVSwipeBanner alloc] initWithFrame:CGRectMake(0, 0, 320, 21)];
    [self.headerView addSubview:self.mileTidbitsSwipeView];

    [self.navigationController setNavigationBarHidden:NO];
    
    self.navigationItem.hidesBackButton = YES;
    
    [self.headerView setFrame:CGRectMake(self.headerView.frame.origin.x, self.headerView.frame.origin.y, 320, 31)];

    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(shareMiles)];
    [self.headerView addGestureRecognizer:tapGestureRecognizer];
}

#pragma mark Funky, Dirty, Native :)

- (id)init {
    
    if (self = [super init]) {
        
        self.navigationItem.title = @"Flights";
        self.tabBarItem.title = @"Flights";
        self.tabBarItem.image = [UIImage imageNamed:@"airplane.png"];
        
        dispatch_async(dispatch_get_main_queue(), ^{

            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshedFlights) name:NSNotificationRecordedNewFlight object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshedFlights) name:NSNotificationDownloadedFlights object:nil];
        });
    }
    
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:YES];
    
    [self updateMilesLabel];
    [self updateFlights];
}

- (void)viewDidDisappear:(BOOL)animated {
    
    self.shouldRefresh = NO;
}

- (void)viewDidLoad {
    
    if (![[NSUserDefaults standardUserDefaults] objectForKey:@"shownAlert"] && ![[TVDatabase currentAccount] isUsingLinkedIn]) {
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Add LinkedIn account?" message:@"Add your LinkedIn account in the Settings page, and effortlessly connect with people you know in the Find People page." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil, nil];
        
        [alertView show];
        
        [[NSUserDefaults standardUserDefaults] setObject:@"set" forKey:@"shownAlert"];
    }
    
    [self UIBuffer];
    
    [self updateFlights];
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refreshControlDidBeginRefreshing:) forControlEvents:UIControlEventValueChanged];
    [self.flightsTable addSubview:refreshControl];
    
    [self refreshAccount:refreshControl];
    
    detailView = [[TVFlightDetailViewController alloc] init];
    
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)refreshControlDidBeginRefreshing:(UIRefreshControl *)refreshControl {
    
    self.shouldRefresh = YES;
    
    [self refreshAccount:refreshControl];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end