
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
@synthesize shouldRefresh, mileTidbitsSwipeView;

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

    [self.headerView setFrame:CGRectMake(self.headerView.frame.origin.x, self.headerView.frame.origin.y, 320, 80)];
    
    self.flightsTable.tableHeaderView = self.headerView;
        
    int numberOfUnreadMessagesNotifications = 0;
    int numberOfConnectRequestNotifications = 0;
    
    for (TVNotification *notification in [[[TVDatabase currentAccount] person] notifications]) {
        
        if (notification.type == (NotificationType *)kNotificationTypeUnreadMessages) {
            
            numberOfUnreadMessagesNotifications++;
        }
        else {
            
            numberOfConnectRequestNotifications++;
        }
    }

    CustomBadge *unreadMessagesBadge = nil;
    
    for (UIView *view in self.headerView.subviews) {
        
        if ([[view accessibilityIdentifier] isEqualToString:@"MessagesBadge"]) {
            
            unreadMessagesBadge = (CustomBadge *)view;
        }
    }

    if (numberOfUnreadMessagesNotifications) {
        
        if (!unreadMessagesBadge) {
            
            unreadMessagesBadge = [CustomBadge customiOS7BadgeWithString:[NSString stringWithFormat:@"%i", numberOfUnreadMessagesNotifications]];
            
            [unreadMessagesBadge setFrame:CGRectMake(70, 33, unreadMessagesBadge.frame.size.width, unreadMessagesBadge.frame.size.height)];
            
            unreadMessagesBadge.userInteractionEnabled = NO;
            
            unreadMessagesBadge.accessibilityIdentifier = @"MessagesBadge";
            
            [self.headerView addSubview:unreadMessagesBadge];
        }
        else {
            
            [unreadMessagesBadge autoBadgeSizeWithString:[NSString stringWithFormat:@"%i", numberOfUnreadMessagesNotifications]];
            
            unreadMessagesBadge.badgeText = [NSString stringWithFormat:@"%i", numberOfUnreadMessagesNotifications];
        }
    }
    else {
        
        if (unreadMessagesBadge) {
            
            [unreadMessagesBadge removeFromSuperview];
        }
    }
    
    CustomBadge *connectBadge = nil;

    for (UIView *view in self.headerView.subviews) {
        
        if ([[view accessibilityIdentifier] isEqualToString:@"ConnectBadge"]) {
            
            connectBadge = (CustomBadge *)view;
        }
    }

    if (numberOfConnectRequestNotifications) {
        
        if (!connectBadge) {
            
            connectBadge = [CustomBadge customiOS7BadgeWithString:[NSString stringWithFormat:@"%i", numberOfConnectRequestNotifications]];
            
            [connectBadge setFrame:CGRectMake(130, 33, connectBadge.frame.size.width, connectBadge.frame.size.height)];
            
            connectBadge.userInteractionEnabled = NO;
            
            connectBadge.accessibilityIdentifier = @"ConnectBadge";
            
            [self.headerView addSubview:connectBadge];
        }
        else {
            
            [connectBadge autoBadgeSizeWithString:[NSString stringWithFormat:@"%i", numberOfConnectRequestNotifications]];

            connectBadge.badgeText = [NSString stringWithFormat:@"%i", numberOfConnectRequestNotifications];
        }
    }
    else {
        
        if (connectBadge) {
            
            [connectBadge removeFromSuperview];
        }
    }
}

- (void)updateFlights {
    
    [self.flightsTable reloadData];
    [self.flightsTable setNeedsDisplay];
}

- (void)refreshAccount:(UIRefreshControl *)refreshControl {
    
    if (shouldRefresh) {
        
        [refreshControl beginRefreshing];
        [self.flightsTable setContentOffset:CGPointMake(0, -refreshControl.frame.size.height) animated:YES];
        
        [TVDatabase refreshAccountWithCompletionHandler:^(BOOL completed) {
            
            [self updateFlights];
            [self updateMilesLabel];
            [self updateNotifications];

            if (completed) {
                
                loading = NO;
                
                if (refreshControl) {
                    
                    [refreshControl endRefreshing];
                }
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
        
        retVal = [[[[TVDatabase currentAccount] person] sortedFlights] count];
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
        
        [detailView setFlightID:[((TVFlight *)[[[TVDatabase currentAccount] person] sortedFlights][indexPath.row]) ID]];
        
        [self.navigationController pushViewController:detailView animated:YES];
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
             firstColor:[UIColor clearColor]
             secondStateIconName:@"cross.png"
             secondColor:[UIColor clearColor]
             thirdIconName:@"cross.png"
             thirdColor:[UIColor clearColor]
             fourthIconName:@"cross.png"
             fourthColor:[UIColor clearColor]];
            [(TVFlightCell *)cell setMode:MCSwipeTableViewCellModeExit];
            
            [(TVFlightCell *)cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        }
        
        TVFlight *flight = [[[TVDatabase currentAccount] person] sortedFlights][indexPath.row];
        
        ((TVFlightCell *)cell).flight.text = [NSString stringWithFormat:@"%@ to %@", flight.originCity, flight.destinationCity];
        
        ((TVFlightCell *)cell).shortMiles.text = [self generateShortcuttedMiles:[flight miles]];
        
        ((TVFlightCell *)cell).shortDate.text = [self generateShortcuttedDates:[flight date]];
        
        ((TVFlightCell *)cell).flight.font = [UIFont fontWithName:@"Gotham Book" size:15.0f];
        
        if (loading) {
            
            [(TVFlightCell *)cell setShouldDrag:NO];
        }
        else {
            
            [(TVFlightCell *)cell setShouldDrag:YES];
        }
    }
    
    return cell;
}

- (void)swipeTableViewCell:(MCSwipeTableViewCell *)cell didTriggerState:(MCSwipeTableViewCellState)state withMode:(MCSwipeTableViewCellMode)mode {
    
    if (mode == MCSwipeTableViewCellModeExit && cell.shouldDrag) {
        
        int row = [[self.flightsTable indexPathForCell:(TVFlightCell *)cell] row];
        
        TVAccount *account = [TVDatabase currentAccount];
        [[account person] deleteFlight:[[account person] sortedFlights][row]];
        
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

#pragma mark Actions

- (void)showMessagesPage {
    
    TVMessageListViewController *messageListViewController = [[TVMessageListViewController alloc] init];
    [self.navigationController pushViewController:messageListViewController animated:YES];
}

- (void)showFindPeoplePage {
 
    [findPeople setFilter:(FindPeopleFilter *)kFindPeopleFilterSuggestions];
    [[self navigationController] pushViewController:findPeople animated:YES];
}

- (void)exportFlights {
 
    NSMutableString *csv = [NSMutableString stringWithString:@"Name,Date,Miles"];
 
    for (int i = 0; i <= [[[[TVDatabase currentAccount] person] flights] count] - 1; i++ ) {

        TVFlight *flight = [[[TVDatabase currentAccount] person] flights][i];
        
        [csv appendFormat:@"\n\"%@\",%@,\"%g\"", flight.originCity, flight.destinationCity, flight.miles];
    }
    
    NSString *fileName = [NSString stringWithFormat:@"%@_%@_Flights", [[[[TVDatabase currentAccount] person] name] componentsSeparatedByString:@" "][0], [[[[[TVDatabase currentAccount] person] name] componentsSeparatedByString:@" "] lastObject]];
    
    NSError *error;
    BOOL res = [csv writeToFile:[NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"Documents/%@", fileName]] atomically:YES encoding:NSUTF8StringEncoding error:&error];
    
    if (!res) {
        
        [TVErrorHandler handleError:[NSError errorWithDomain:@"Could not export" code:200 userInfo:@{NSLocalizedDescriptionKey: @"Could not export flights"}]];
    }
    else {
        
        if ([MFMailComposeViewController canSendMail] && [[[TVDatabase currentAccount] person] flights].count) {
            
            MFMailComposeViewController *composeViewController = [[MFMailComposeViewController alloc] init];
            [composeViewController setSubject:@"My Flights"];
            [composeViewController addAttachmentData:[NSData dataWithContentsOfFile:fileName] mimeType:@"text/csv" fileName:fileName];
            
            composeViewController.mailComposeDelegate = self;
            
            [self presentViewController:composeViewController animated:YES completion:nil];
        }
        else {
            
            [TVErrorHandler handleError:[NSError errorWithDomain:@"Ensure you have added a mail account in Settings" code:200 userInfo:@{NSLocalizedDescriptionKey: @"Ensure you have added a mail account in Settings"}]];
        }
    }
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    
    if (result == MFMailComposeResultSent) {
        
        [TVNotificationSignifier signifyNotification:@"Exported flights and sent email" forDuration:3];
    }
    else if ((result == MFMailComposeResultSaved) || (result == MFMailComposeResultCancelled)) {
        
    }
    else {
        
        [TVErrorHandler handleError:[NSError errorWithDomain:@"Couldn't send email" code:200 userInfo:@{NSLocalizedDescriptionKey: @"Could not send email"}]];
    }
    
    [controller dismissViewControllerAnimated:YES completion:nil];
}

- (void)showSettingsPage {
    
    [self logout];
}

- (void)logout {
    
    TVLoginViewController *login = [[TVLoginViewController alloc] init];
    [self.navigationController pushViewController:login animated:YES];
    
    [TVDatabase logout];
}

#pragma mark UI Handling

- (void)UIBuffer {
    
    // Do some Funky, Dirty, Native stuff here. JK
    
    self.mileTidbitsSwipeView = [[TVSwipeBanner alloc] initWithFrame:CGRectMake(0, 0, 320, 21)];
    [self.headerView addSubview:self.mileTidbitsSwipeView];
    
    [self.navigationController setNavigationBarHidden:NO];
    
    self.navigationItem.hidesBackButton = YES;

    UIBarButtonItem *recordFlightItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(recordAFlight)];
    self.navigationItem.leftBarButtonItem = recordFlightItem;
            
    [self.headerView setFrame:CGRectMake(self.headerView.frame.origin.x, self.headerView.frame.origin.y, 320, 80)];
    
    UIButton *messages = [[UIButton alloc] init];
    [messages setImage:[UIImage imageNamed:@"messages.png"] forState:UIControlStateNormal];
    [messages setFrame:CGRectMake(55, 42, 28.94, 25)];
    [messages addTarget:self action:@selector(showMessagesPage) forControlEvents:UIControlEventTouchUpInside];
    [self.headerView addSubview:messages];
    
    UIButton *_findPeople = [[UIButton alloc] init];
    [_findPeople setImage:[UIImage imageNamed:@"people.png"] forState:UIControlStateNormal];
    [_findPeople setFrame:CGRectMake(120, 41, 25, 27.38)];
    [_findPeople addTarget:self action:@selector(showFindPeoplePage) forControlEvents:UIControlEventTouchUpInside];
    [self.headerView addSubview:_findPeople];
    
    UIButton *exportFlights = [[UIButton alloc] init];
    [exportFlights setImage:[UIImage imageNamed:@"export.png"] forState:UIControlStateNormal];
    [exportFlights setFrame:CGRectMake(174, 42, 28, 28)];
    [exportFlights addTarget:self action:@selector(exportFlights) forControlEvents:UIControlEventTouchUpInside];
    [self.headerView addSubview:exportFlights];

    UIButton *settings = [[UIButton alloc] init];
    [settings setImage:[UIImage imageNamed:@"settings.png"] forState:UIControlStateNormal];
    [settings setFrame:CGRectMake(227, 42, 28, 28)];
    [settings addTarget:self action:@selector(showSettingsPage) forControlEvents:UIControlEventTouchUpInside];
    [self.headerView addSubview:settings];
}

#pragma mark Funky, Dirty, Native :)

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:YES];
    
    [self updateNotifications];
    [self updateMilesLabel];
    [self updateFlights];
}

- (void)viewDidDisappear:(BOOL)animated {
    
    self.shouldRefresh = NO;
}

- (void)refreshAccountWithControl:(UIRefreshControl *)refreshControl {
    
    self.shouldRefresh = YES;

    [self refreshAccount:refreshControl];
}

- (void)viewDidLoad {
    
    loading = YES;
    
    [self UIBuffer];
    
    [self updateFlights];
    
    findPeople = [[TVFindPeopleViewController alloc] init];
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refreshAccountWithControl:) forControlEvents:UIControlEventValueChanged];
    [self.flightsTable addSubview:refreshControl];
    
    [self refreshAccount:refreshControl];
    
    detailView = [[TVFlightDetailViewController alloc] init];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accountUpdated) name:@"RecordedFlight" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accountUpdated) name:@"RefreshedAccount" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshedFlights) name:@"RefreshedFlights" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(manuallyRefreshAccount) name:@"ManuallyRefreshAccount" object:nil];

    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)manuallyRefreshAccount {
    
    self.shouldRefresh = YES;
    [self refreshAccount:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end