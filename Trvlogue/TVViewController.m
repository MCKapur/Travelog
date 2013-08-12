
//  TrvlogueViewController.m
//  Trvlogue
//
//  Created by Rohan Kapur on 11/3/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import "TVViewController.h"

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

@implementation TVViewController

- (void)accountUpdated {
    
    [self updateNotifications];
}

- (void)refreshedFlights {
    
    loading = NO;
    
    [self updateFlights];
    [self updateMilesLabel];
}

#pragma mark UITableView Methods

- (void)updateNotifications {    
    
    if (![self.view.subviews containsObject:self.notificationsTable])
        [self.headerView addSubview:self.notificationsTable];
    
    [self.notificationsTable setFrame:CGRectMake(0, 27, 320, 66 * [[[[TVDatabase currentAccount] person] notifications] collectiveNotifications].count)];
    
    [self.headerView setFrame:CGRectMake(self.headerView.frame.origin.x, self.headerView.frame.origin.y, self.headerView.frame.size.width, 31 + (27 * [[[[TVDatabase currentAccount] person] notifications] collectiveNotifications].count))];
    
    self.flightsTable.tableHeaderView = self.headerView;
    
    [self.notificationsTable reloadData];
    [self.notificationsTable setNeedsDisplay];
}

- (void)updateFlights {
    
    [self.flightsTable reloadData];
    [self.flightsTable setNeedsDisplay];
}

- (void)refreshAccount:(UIRefreshControl *)refreshControl {

    dispatch_queue_t downloadQueue = dispatch_queue_create("Refresh", NULL);
    
    dispatch_async(downloadQueue, ^{
        
        Reachability *reach = [Reachability reachabilityWithHostname:@"google.com"];
        
        if ([reach isReachable] && ([reach isReachableViaWiFi] || [reach isReachableViaWWAN])) {
            
            loading = YES;
            
            [self.flightsTable reloadData];
            [self.flightsTable setNeedsDisplay];
            
            [TVDatabase refreshAccountWithCompletionHandler:^(BOOL completed) {
                
                if (completed) {
                    
                    loading = NO;
                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    if (refreshControl) {
                        
                        [refreshControl endRefreshing];
                    }

                    [self updateFlights];
                    [self updateMilesLabel];
                    [self updateNotifications];
                    
                });
            }];
        }
        else {
            
            loading = NO;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if (refreshControl) {
                    
                    [refreshControl endRefreshing];
                }
                
                [self updateFlights];
                [self updateMilesLabel];
                [self updateNotifications];
            });
        }
    });
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

        retVal = [[[TVDatabase currentAccount] sortedFlights] count];
    }
    else if (tableView == self.notificationsTable) {

        retVal = [[[[[TVDatabase currentAccount] person] notifications] collectiveNotifications] count];
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
        
        [detailView setFlightID:[((TVFlight *)[[TVDatabase currentAccount] sortedFlights][indexPath.row]) ID]];
        [detailView updateMap];
        
        [self.navigationController pushViewController:detailView animated:YES];
    }
    else {
        
        if (((TVNotification *)[[[[TVDatabase currentAccount] person] notifications] collectiveNotifications][indexPath.row]).type == kNotificationTypeConnectionRequest) {
            
            TVFindPeopleViewController *findPeopleViewController = [[TVFindPeopleViewController alloc] init];
            [findPeopleViewController setFilter:(FindPeopleFilter *)kFindPeopleOnlyConnectRequests];
            
            [[self navigationController] pushViewController:findPeopleViewController animated:YES];
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    NSString *FlightCell = @"FlightTableCell_%@";
    NSString *NotificationsCell = @"NotificationsCell_%@";
    
    NSString *CellIdentifier = nil;

    if (tableView == self.flightsTable) {
        
        CellIdentifier = FlightCell;
    }
    else {

        CellIdentifier = NotificationsCell;
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
            
            [(TVFlightCell *)cell setDelegate:self];
            [(TVFlightCell *)cell
                        setFirstStateIconName:@"cross.png"
                            firstColor:[UIColor redColor]
                        secondStateIconName:@"cross.png"
                            secondColor:[UIColor redColor]
                        thirdIconName:@"cross.png"
                            thirdColor:[UIColor redColor]
                        fourthIconName:@"cross.png"
                            fourthColor:[UIColor redColor]];
            [(TVFlightCell *)cell setMode:MCSwipeTableViewCellModeExit];
            
            [(TVFlightCell *)cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        }
        
        TVFlight *flight = [[TVDatabase currentAccount] sortedFlights][indexPath.row];
        
        ((TVFlightCell *)cell).flight.text = [NSString stringWithFormat:@"%@ to %@", flight.originCity, flight.destinationCity];
        
        ((TVFlightCell *)cell).shortMiles.text = [self generateShortcuttedMiles:[flight miles]];
        
        ((TVFlightCell *)cell).shortDate.text = [self generateShortcuttedDates:[flight date]];
        
        ((TVFlightCell *)cell).flight.font = [UIFont fontWithName:@"Gotham Book" size:15.0];

        if (loading) {
            
            [(TVFlightCell *)cell setShouldDrag:NO];
        }
        else {
            
            [(TVFlightCell *)cell setShouldDrag:YES];
        }
    }
    else {

        if (!cell) {
            
            NSArray *views = [[NSBundle mainBundle] loadNibNamed:@"TVNotificationCell" owner:self options:nil];
            
            for (UIView *view in views) {
                
                if ([view isKindOfClass:[UITableViewCell class]])
                {
                    cell = (TVNotificationCell *)view;
                }
            }
            
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            cell.backgroundColor = [UIColor clearColor];
        }
        
        if ([[[[TVDatabase currentAccount] person] notifications] collectiveNotifications].count) {
            
            ((TVNotificationCell *)cell).titleLabel.text = ((TVNotification *)[[[[TVDatabase currentAccount] person] notifications] collectiveNotifications][indexPath.row]).title;
            
            ((TVNotificationCell *)cell).titleLabel.textColor = [UIColor blueColor];
        }
    }
    
    return cell;
}

- (void)swipeTableViewCell:(MCSwipeTableViewCell *)cell didTriggerState:(MCSwipeTableViewCellState)state withMode:(MCSwipeTableViewCellMode)mode {

    if (mode == MCSwipeTableViewCellModeExit && cell.shouldDrag) {
        
        int row = [[self.flightsTable indexPathForCell:(TVFlightCell *)cell] row];
        
        TVAccount *account = [TVDatabase currentAccount];
        [account deleteFlight:[account sortedFlights][row]];

        [TVDatabase updateMyAccount:account withCompletionHandler:^(BOOL succeeded, NSError *error, NSString *callCode) {
        }];

        [self.flightsTable beginUpdates];
        [self.flightsTable deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForItem:row inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
        [self.flightsTable endUpdates];
        
        [self updateMilesLabel];
    }
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

- (NSMutableArray *)fetchMileTidbits {
    
    return [[[TVDatabase currentAccount] person] mileTidbits];
}

- (void)updateMilesLabel {

    double miles = 0.0f;
    
    for (TVFlight *flight in [[TVDatabase currentAccount] flights]) {
        
        miles += flight.miles;
    }
    
    [self.mileTidbitsSwipeView setTidbits:[NSMutableArray arrayWithObject:@(miles)] andMode:kTVSwipeBannerModeMileTidbits];
}

#pragma mark Flight Recording + Delegate

- (void)recordAFlight {
    
    TVFlightRecorderViewController *flightRecorder = [[TVFlightRecorderViewController alloc] init];
    [self.navigationController pushViewController:flightRecorder animated:YES];
}

#pragma mark Find People

- (void)connectView {
    
    TVFindPeopleViewController *findPeople = [[TVFindPeopleViewController alloc] init];
    [findPeople setFilter:kFindPeopleFilterAllPeople];
    
    [[self navigationController] pushViewController:findPeople animated:YES];
}

#pragma mark UI Handling

- (void)UIBuffer {
    
    // Do some Funky, Dirty, Native stuff here. JK
    
    self.mileTidbitsSwipeView = [[TVSwipeBanner alloc] initWithFrame:CGRectMake(0, 0, 320, 21)];
    [self.headerView addSubview:self.mileTidbitsSwipeView];
    
    [self.navigationController setNavigationBarHidden:NO];
    
    self.navigationItem.hidesBackButton = YES;

    UIBarButtonItem *recordFlightItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(recordAFlight)];
    self.navigationItem.rightBarButtonItem = recordFlightItem;
    
    UIBarButtonItem *barButtonItemConnect = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"person.png"] landscapeImagePhone:nil style:UIBarButtonItemStylePlain target:self action:@selector(connectView)];
    self.navigationItem.leftBarButtonItem = barButtonItemConnect;
        
    UIButton *logoutButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    logoutButton.frame = self.navigationItem.titleView.frame;
    logoutButton.alpha = 0.02f;
    [logoutButton addTarget:self action:@selector(logout) forControlEvents:UIControlEventTouchUpInside];
    
    [self.navigationItem setTitleView:logoutButton];
    
    self.notificationsTable = [[UITableView alloc] initWithFrame:CGRectMake(0, 27, 320, 66 * [[[[TVDatabase currentAccount] person] notifications] collectiveNotifications].count) style:UITableViewStylePlain];
    
    self.notificationsTable.separatorColor = [UIColor clearColor];
    self.notificationsTable.backgroundColor = [UIColor clearColor];
    
    self.notificationsTable.dataSource = self;
    self.notificationsTable.delegate = self;
    
    [self.headerView setFrame:CGRectMake(self.headerView.frame.origin.x, self.headerView.frame.origin.y, self.headerView.frame.size.width, 31 + (27 * [[[[TVDatabase currentAccount] person] notifications] collectiveNotifications].count))];
    
    [self.headerView addSubview:self.notificationsTable];
}

- (void)logout {
    
    TVLoginViewController *login = [[TVLoginViewController alloc] init];
    [self.navigationController pushViewController:login animated:YES];
    
    [TVDatabase logout];
}

#pragma mark Funky, Dirty, Native :)

- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:YES];

    [self updateNotifications];
    [self updateMilesLabel];
    [self updateFlights];
}

- (void)viewDidLoad {
    
    loading = YES;
    
    [self UIBuffer];
    
    [self updateFlights];

    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refreshAccount:) forControlEvents:UIControlEventValueChanged];
    [self.flightsTable addSubview:refreshControl];
    
    [refreshControl beginRefreshing];
    [self.flightsTable setContentOffset:CGPointMake(0, -refreshControl.frame.size.height) animated:YES];
    
    [self refreshAccount:refreshControl];

    detailView = [[TVFlightDetailViewController alloc] init];
    [detailView setTravelMap:[[MKMapView alloc] init]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accountUpdated) name:@"RecordedFlight" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accountUpdated) name:@"RefreshedAccount" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshedFlights) name:@"RefreshedFlights" object:nil];
    
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end