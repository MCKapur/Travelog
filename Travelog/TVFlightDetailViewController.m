//
//  TrvlogueFlightDetailViewController.m
//  Trvlogue
//
//  Created by Rohan Kapur on 23/3/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#define NUMBER_OF_PAGES 4

#import "TVFlightDetailViewController.h"

@interface TVFlightDetailViewController ()

@end

@implementation TVFlightDetailViewController
@synthesize FlightID, travelInfoBanner, peopleTableView;

- (void)handleError:(NSError *)error andType:(NSString *)type {
    
    [TVErrorHandler handleError:[NSError errorWithDomain:[NSString stringWithFormat:@"Could not %@", type] code:200 userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"Could not %@", type]}]];
}

#pragma mark Travel Data

- (NSMutableDictionary *)travelData {

    return [TVDatabase travelDataPacketWithID:self.FlightID];
}

- (IBAction)changedSegmentedControl:(UISegmentedControl *)sender {
}

- (void)tidbitClicked:(NSNotification *)notification {

    if ([notification.userInfo[@"ID"] isEqualToString:@"Plugs"]) {
        
        CustomIOS7AlertView *alertView = [[CustomIOS7AlertView alloc] init];
        
        __block UIView *containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 240, 166)];
        
        UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, 240, 166)];
        scrollView.tag = 200;
        scrollView.pagingEnabled = YES;
        scrollView.showsHorizontalScrollIndicator = NO;
        scrollView.showsVerticalScrollIndicator = NO;
        scrollView.scrollsToTop = NO;
        scrollView.delegate = self;
        scrollView.bounces = NO;
        
        NSInteger numberOfPlugs = [[self travelData][@"plugs"][@"numberOfPlugs"] intValue];
        
        scrollView.contentSize = CGSizeMake(scrollView.frame.size.width * numberOfPlugs, 0);
        
        for (NSInteger i = 0; i <= numberOfPlugs - 1; i++) {
            
            NSString *letter = [[self travelData][@"plugs"][@"plugs"][i] substringToIndex:1];
            NSMutableArray *images = [self travelData][@"plugs"][@"images"];

            UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:images[i][letter]]];
            
            CGRect frame = scrollView.frame;
            frame.origin.x = frame.size.width * i;
            frame.origin.y = 0;
            
            imageView.frame = frame;
            
            [scrollView addSubview:imageView];
        }
        
        [containerView addSubview:scrollView];
        
        UIPageControl *pageControl = [[UIPageControl alloc] init];
        [pageControl setNumberOfPages:numberOfPlugs];
        [pageControl setCurrentPageIndicatorTintColor:[UIColor darkGrayColor]];
        [pageControl setPageIndicatorTintColor:[UIColor lightGrayColor]];
        [pageControl setFrame:CGRectMake(-20, 155, 290, pageControl.frame.size.height)];
        [containerView addSubview:pageControl];
        [containerView bringSubviewToFront:pageControl];

        [alertView setContainerView:containerView];

        [alertView setButtonTitles:[NSMutableArray arrayWithObjects:@"Dismiss", nil]];
        [alertView setOnButtonTouchUpInside:^(CustomIOS7AlertView *alertView, NSInteger buttonIndex) {
            
            containerView = nil;
            
            [alertView close];
        }];

        [alertView setUseMotionEffects:true];
        
        [alertView show];
    }
    else if ([notification.userInfo[@"ID"] isEqualToString:@"Languages"]) {

        [translationsViewController setTranslations:[self travelData][@"languages"]];
        
        [self.navigationController pushViewController:translationsViewController animated:YES];
    }
}

#pragma mark TrvlogueFlight-TravelData Delegate

- (void)travelDataUpdated:(NSNotification *)notification {
    
    TravelDataTypes *dataType = (TravelDataTypes *)[notification.userInfo[@"dataType"] intValue];

    [self initializeInfoWithType:(NSInteger)dataType];

    if ((NSInteger)dataType == kTravelDataPeople) {
        
        [self reloadPeople];
    }
    else if ((NSInteger)dataType == kTravelDataCurrentNews) {

        [self.newsTableView reloadData];
        [self.newsTableView setNeedsDisplay];
    }
    else if ((NSInteger)dataType == kTravelDataWeather) {

        [self.weatherTableView reloadData];
        [self.weatherTableView setNeedsDisplay];
    }
    else if ((NSInteger)dataType == kTravelDataLanguagesSpoken) {
        
        [translationsViewController setTranslations:[self travelData][@"languages"]];
    }
    
    [self pollForTravelInfoBanner];
}

#pragma mark UISearchBar Delegate Methods

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    
    placesIsSearching = YES;
    
    [searchBar resignFirstResponder];
    
    [self reloadPlacesData];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    
    if (![[searchBar text] length]) {
        
        placesIsSearching = NO;
        
        [self.placesTableView reloadData];
        [self.placesTableView setNeedsDisplay];
    }
    
    [searchBar resignFirstResponder];
}

#pragma mark Places Methods

- (void)savedPlace:(TVGooglePlace *)place {

    [TVDatabase savePlace:place withCity:[TVDatabase flightFromID:self.FlightID].destinationCity];
    
    [self.placesTableView reloadData];
    [self.placesTableView setNeedsDisplay];
}

- (void)reloadPlacesData {
    
    if ([[[self.searchBar text] stringByReplacingOccurrencesOfString:@" " withString:@""] length]) {

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, (unsigned long)NULL), ^{
            
            [searchedPlaces removeAllObjects];
            
            [placeFinder findPlacesBasedOnInput:[NSString stringWithFormat:@"%@ in %@, %@", self.searchBar.text, [TVDatabase flightFromID:self.FlightID].destinationCity, [TVDatabase flightFromID:self.FlightID].destinationCountry] withCompletionHandler:^(NSError *error, NSMutableArray *_places) {

                [searchedPlaces addObjectsFromArray:_places];
                
                dispatch_async(dispatch_get_main_queue(), ^{

                    [self.placesTableView reloadData];
                    [self.placesTableView setNeedsDisplay];
                });
            }];
        });
    }
}

#pragma mark Table View Methods

#pragma mark (SUBMARK) UIGridView

- (CGFloat)gridView:(UIGridView *)grid widthForColumnAt:(NSInteger)columnIndex
{
	return (float)320/3.05;
}

- (CGFloat)gridView:(UIGridView *)grid heightForRowAt:(NSInteger)rowIndex
{
	return (float)105;
}

- (NSInteger)numberOfColumnsOfGridView:(UIGridView *)grid
{
	return 3;
}

- (NSInteger)numberOfCellsOfGridView:(UIGridView *)grid
{
    NSInteger retVal = [[self travelData][@"people"] count];
    
	return retVal;
}

- (UIGridViewCell *)gridView:(UIGridView *)grid cellForRowAt:(NSInteger)rowIndex AndColumnAt:(NSInteger)columnIndex {

    if (!rowIndex && !columnIndex) {
        
        gridNumber = 0;
        [gridConvert removeAllObjects];
    }
        
	TVPersonCell *cell = (TVPersonCell *)[grid dequeueReusableCell];
	
	if (!cell) {
        
		cell = [[TVPersonCell alloc] init];
        
        if (cell) {
            
            cell.profilePicture.image = [TVDatabase locateProfilePictureOnDiskWithUserId:[TVDatabase cachedAccountWithId:[self travelData][@"people"][gridNumber]].userId];
            cell.name.text = [TVDatabase cachedAccountWithId:[self travelData][@"people"][gridNumber]].person.name;

            gridConvert[[NSString stringWithFormat:@"(%i,%i)", rowIndex, columnIndex]] = @(gridNumber);
            gridNumber++;
        }
    }
        
	return cell;
}

- (void)gridView:(UIGridView *)grid didSelectRowAt:(NSInteger)rowIndex AndColumnAt:(NSInteger)colIndex
{
	NSString *coordinate = [NSString stringWithFormat:@"(%i,%i)", rowIndex, colIndex];
    
    NSInteger index = [gridConvert[coordinate] intValue];
    
    TVMessageDetailViewController *messageDetailViewController;
    
    if ([TVDatabase messageHistoryIDFromRecipients:[[NSMutableArray alloc] initWithObjects:[self travelData][@"people"][index], [TVDatabase currentAccount].userId, nil]]) {

        messageDetailViewController = [[TVMessageDetailViewController alloc] initWithMessageHistoryID:[TVDatabase messageHistoryIDFromRecipients:[[NSMutableArray alloc] initWithObjects:[self travelData][@"people"][index], [TVDatabase currentAccount].userId, nil]]];
    }
    else {
        
        TVMessageHistory *messageHistory = [[TVMessageHistory alloc] initWithSenderId:[[TVDatabase currentAccount] userId] andReceiverId:[self travelData][@"people"][index] andMessages:[[NSMutableArray alloc] init]];
        
        TVAccount *newAccount = [TVDatabase currentAccount];
        [newAccount.person.messageHistories addObject:messageHistory];

        [TVDatabase updateMyCache:newAccount];

        messageDetailViewController = [[TVMessageDetailViewController alloc] initWithMessageHistoryID:messageHistory.ID];
    }

    [self.navigationController pushViewController:messageDetailViewController animated:YES];
}

#pragma mark (SUBMARK) UITableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    NSInteger retVal = 0;
    
    if (tableView == self.newsTableView) {

        self.newsTableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        
        retVal = [[self travelData][@"news"] count];
    }
    else if (tableView == self.weatherTableView) {
        
        self.weatherTableView.separatorStyle = UITableViewCellSeparatorStyleNone;

        retVal = [[self travelData][@"weather"] count];

        NSDate *dateStart = [[self travelData][@"weather"] firstObject][@"date"];
        NSDate *dateEnd = [[self travelData][@"weather"] lastObject][@"date"];
        
        self.weatherTimestamp.text = [NSString stringWithFormat:@"%@ - %@", [TVConversions convertDateToString:dateStart withFormat:DAY_MONTH], [TVConversions convertDateToString:dateEnd withFormat:DAY_MONTH]];
    }
    else if (tableView == self.placesTableView) {
        
        retVal = placesIsSearching ? searchedPlaces.count : [TVDatabase getSavedPlacesWithCity:[TVDatabase flightFromID:self.FlightID].destinationCity].count;
    }
    
    return retVal;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *CELL_ID = nil;
    
    NSString *NEWS_CELL_ID = @"NewsCell";
    
    NSString *WEATHER_CELL_ID = @"WeatherCell";
    
    NSString *PLACES_CELL_ID = @"PlacesCell";

    if (tableView == self.newsTableView) {
        
        CELL_ID = NEWS_CELL_ID;
    }
    else if (tableView == self.weatherTableView) {
                
        CELL_ID = WEATHER_CELL_ID;
    }
    else {

        CELL_ID = PLACES_CELL_ID;
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CELL_ID];
    
    if ([CELL_ID isEqualToString:NEWS_CELL_ID]) {

        if (!cell) {
            
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CELL_ID];
            
            cell.textLabel.text = nil;
            cell.detailTextLabel.text = nil;
            cell.imageView.image = nil;
            
            cell.textLabel.font = [UIFont fontWithName:@"System" size:12.0];
            cell.textLabel.textColor = [UIColor darkGrayColor];
            
            cell.layer.cornerRadius = 7.0f;
            cell.layer.masksToBounds = YES;
            
            cell.backgroundColor = [UIColor clearColor];
            
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            
            cell.textLabel.numberOfLines = 2;
        }

        cell.textLabel.text = ((TVRSSItem *)[self travelData][@"news"][indexPath.row]).title;
    }
    else if ([CELL_ID isEqualToString:WEATHER_CELL_ID]) {
                        
        if (!cell) {
            
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CELL_ID];
            
            cell.textLabel.text = nil;
            cell.detailTextLabel.text = nil;
            cell.imageView.image = nil;
                            
            cell.textLabel.font = [UIFont fontWithName:@"System" size:13.0];
            cell.textLabel.textColor = [UIColor blackColor];
            
            cell.detailTextLabel.font = [UIFont fontWithName:@"System" size:15.0];
            cell.detailTextLabel.textColor = [UIColor blackColor];
            
            cell.layer.cornerRadius = 7.0f;
            cell.layer.masksToBounds = YES;
            
            cell.backgroundColor = [UIColor clearColor];
            
            cell.selectionStyle = UITableViewCellSelectionStyleNone;

            cell.textLabel.numberOfLines = 2;
                        
            cell.detailTextLabel.accessibilityIdentifier = @"F";
            
            cell.imageView.layer.masksToBounds = YES;
            cell.imageView.layer.cornerRadius = 5.0;
        }
        
        NSDateFormatter *dayFormatter = [[NSDateFormatter alloc] init];
        [dayFormatter setDateFormat:@"EEEE"];
        NSDate *date = [self travelData][@"weather"][indexPath.row][@"date"];
        
        cell.textLabel.text = [NSString stringWithFormat:@"%@ will be %@", [dayFormatter stringFromDate:date], [[self travelData][@"weather"][indexPath.row][@"description"] lowercaseString]];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%i°F - %i°F", (NSInteger)([[self travelData][@"weather"][indexPath.row][@"minF"] doubleValue] + 0.5), (NSInteger)([[self travelData][@"weather"][indexPath.row][@"maxF"] doubleValue] + 0.5)];
        
        cell.imageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"%@.png", [self travelData][@"weather"][indexPath.row][@"icon"]]];
        
        cell.textLabel.font = [UIFont fontWithName:@"System" size:12.0];
        cell.textLabel.textColor = [UIColor blackColor];
    }
    else {

        if (!cell) {
                    
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CELL_ID];
            
            cell.textLabel.text = nil;
            cell.detailTextLabel.text = nil;
            cell.imageView.image = nil;
            
            cell.textLabel.adjustsFontSizeToFitWidth = YES;
            cell.textLabel.font = [UIFont systemFontOfSize:15.0];
            cell.textLabel.minimumScaleFactor = 10.0f;
            cell.textLabel.numberOfLines = 4;
            cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
            cell.textLabel.textColor = [UIColor colorWithRed:0.0 green:128.0/255.0 blue:0.0 alpha:1.0];
            cell.textLabel.textAlignment = NSTextAlignmentLeft;
            
            cell.detailTextLabel.textColor = [UIColor darkGrayColor];
            cell.detailTextLabel.font = [UIFont systemFontOfSize:13.0];

            cell.backgroundColor = [UIColor clearColor];
                        
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
                    
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        
        TVGooglePlace *place = placesIsSearching ? searchedPlaces[indexPath.row] : [TVDatabase getSavedPlacesWithCity:[TVDatabase flightFromID:self.FlightID].destinationCity][indexPath.row];

        cell.textLabel.text = [NSString stringWithFormat:@"%@", place.name];
        
        NSMutableString *detail = [[NSMutableString alloc] init];
        
        if (place.rating) {
            
            [detail appendFormat:@"%.1f/5 · ", place.rating];
        }
        
        if (place.priceLevel) {
            
            for (NSInteger i = 1; i <= place.priceLevel; i++) {
                
                [detail appendString:@"$"];
            }
            
            [detail appendString:@" · "];
        }

        if (place.address) {

            [detail appendString:place.address];
        }
        
        cell.detailTextLabel.text = detail;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *CELL_ID = nil;
    
    NSString *NEWS_CELL_ID = @"NewsCell";
    
    NSString *WEATHER_CELL_ID = @"WeatherCell";
    
    NSString *PLACES_CELL_ID = @"PlacesCell";

    if (tableView == self.newsTableView) {
        
        CELL_ID = NEWS_CELL_ID;
    }
    else if (tableView == self.weatherTableView) {

        CELL_ID = WEATHER_CELL_ID;
    }
    else {
        
        CELL_ID = PLACES_CELL_ID;
    }
    
    if ([CELL_ID isEqualToString:NEWS_CELL_ID]) {
        
        TVWebViewController *webViewController = [[TVWebViewController alloc] initWithLink:[NSString stringWithFormat:@"%@",((TVRSSItem *)[self travelData][@"news"][indexPath.row]).link] andTitle:((TVRSSItem *)[self travelData][@"news"][indexPath.row]).title andMakeReadable:YES];
        [self.navigationController pushViewController:webViewController animated:YES];
    }
    else if ([CELL_ID isEqualToString:WEATHER_CELL_ID]) {
        
        if ([[tableView cellForRowAtIndexPath:indexPath].detailTextLabel.accessibilityIdentifier isEqualToString:@"F"]) {

            [tableView cellForRowAtIndexPath:indexPath].detailTextLabel.text = [NSString stringWithFormat:@"%i°C - %i°C", (NSInteger)([[self travelData][@"weather"][indexPath.row][@"minC"] doubleValue] + 0.5), (NSInteger)([[self travelData][@"weather"][indexPath.row][@"maxC"] doubleValue] + 0.5)];
            
            [tableView cellForRowAtIndexPath:indexPath].detailTextLabel.accessibilityIdentifier = @"C";
        }
        else {

            [tableView cellForRowAtIndexPath:indexPath].detailTextLabel.text = [NSString stringWithFormat:@"%i°F - %i°F", (NSInteger)([[self travelData][@"weather"][indexPath.row][@"minF"] doubleValue] + 0.5), (NSInteger)([[self travelData][@"weather"][indexPath.row][@"maxF"] doubleValue] + 0.5)];
            
            [tableView cellForRowAtIndexPath:indexPath].detailTextLabel.accessibilityIdentifier = @"F";
        }
    }
    else {
        
        TVGooglePlace *place = placesIsSearching ? searchedPlaces[indexPath.row] : [TVDatabase getSavedPlacesWithCity:[TVDatabase flightFromID:self.FlightID].destinationCity][indexPath.row];

        [placeDetailViewController setPlace:place];
        [placeDetailViewController setDelegate:self];
        
        [self.navigationController pushViewController:placeDetailViewController animated:YES];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    CGFloat retVal = 44;
    
    if (tableView == self.newsTableView) {
        
        retVal = 65;
    }
    else if (tableView == self.weatherTableView) {
        
        retVal = 90;
    }
    
    return retVal;
}

#pragma mark UIScrollView Delegate

- (void)scrollViewDidScroll:(UIScrollView *)sender {

    if (![sender isKindOfClass:[UITableView class]]) {
        
        if (sender.tag == 200) {
            
            for (UIView *pageControl in [sender.superview subviews]) {
                
                if ([pageControl isKindOfClass:[UIPageControl class]]) {
                    
                    NSInteger page = floor((sender.contentOffset.x - sender.frame.size.width / 2) / sender.frame.size.width) + 1;

                    [((UIPageControl *)pageControl) setCurrentPage:page];
                }
            }
        }
        else {
            
            NSInteger page = floor((sender.contentOffset.x - sender.frame.size.width / 2) / sender.frame.size.width) + 1;
            
            [pageControl setCurrentPage:page];
            
            if (!page) {
                
                self.navigationItem.title = @"Connections";
            }
            else if (page == 1) {
                
                self.navigationItem.title = @"News";
            }
            else if (page == 2) {
                
                self.navigationItem.title = @"Weather";
            }
            else if (page == 3) {
                
                self.navigationItem.title = @"Places";
            }
        }
    }
}

#pragma mark Info Updates

- (void)initializeInfoWithType:(NSInteger)dataType {

    if (dataType == kTravelDataCurrency || dataType == 200) {
        
        NSMutableDictionary *currency = [NSMutableDictionary dictionaryWithObjectsAndKeys:[self travelData][@"currency"], @"data", @"Currency", @"name", nil];
        
        currency[@"accessoryType"] = @(UITableViewCellAccessoryNone);
        
        if ([self travelData][@"currency"][@"o->d"]) {
            
            NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
            [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
            [formatter setMaximumFractionDigits:2];
            
            NSString *formattedNumber = [formatter stringFromNumber:[self travelData][@"currency"][@"o->d"]];
            
            currency[@"detail"] = [NSString stringWithFormat:@"One %@ is %@ %@.", [self travelData][@"currency"][@"originCurrency"], formattedNumber, [self travelData][@"currency"][@"destinationCurrency"]];
        }
        
        info[@"currency"] = currency;
    }

    if (dataType == kTravelDataLanguagesSpoken || dataType == 200) {
        
        NSMutableDictionary *languages_ = [NSMutableDictionary dictionaryWithObjectsAndKeys:[self travelData][@"languages"], @"data", @"Languages", @"name", nil];
        
        NSMutableString *detail = [[NSMutableString alloc] init];

        if ([((NSMutableArray *)[self travelData][@"languages"]) count]) {
            
            for (NSInteger i = 0; i <= [[self travelData][@"languages"] count] - 1; i++) {
                
                [detail appendFormat:@"%@", [self travelData][@"languages"][i][@"name"]];
                
                if (i != [[self travelData][@"languages"] count] - 1) {
                    
                    if (i == [[self travelData][@"languages"] count] - 2) {
                        
                        [detail appendString:@" and "];
                    }
                    else {
                        
                        [detail appendString:@", "];
                    }
                }
            }
            
            languages_[@"detail"] = [[NSString stringWithFormat:@"People speak %@.", detail] mutableCopy];
            
            BOOL hasTranslations = NO;
            
            languages_[@"accessoryType"] = @(UITableViewCellAccessoryNone);

            for (NSMutableDictionary *dictionary in languages_[@"data"]) {
                
                if (dictionary[@"translations"]) {
                    
                    hasTranslations = YES;
                    
                    break;
                }
            }
            
            if (hasTranslations) {
                
                languages_[@"accessoryType"] = @(UITableViewCellAccessoryDisclosureIndicator);
                
                [languages_[@"detail"] appendString:@" Tap for translations."];
            }
        }
        
        info[@"languages"] = languages_;
    }
    
    if (dataType == kTravelDataTimezone || dataType == 200) {
        
        NSMutableDictionary *timezone = [NSMutableDictionary dictionaryWithObjectsAndKeys:[self travelData][@"timezone"], @"data", @"Timezone", @"name", @(UITableViewCellAccessoryNone), @"accessoryType", nil];
        
        float originOffset = [[self travelData][@"timezone"][@"originUTCOffset"] doubleValue];
        float destinationOffset = [[self travelData][@"timezone"][@"destinationUTCOffset"] doubleValue];

        NSString *detail = [[NSString alloc] init];
        NSString *sub = [[NSString alloc] init];
        
        if (destinationOffset != originOffset) {
            
            float offsetFromOriginToDestination = originOffset - destinationOffset;
            
            if (destinationOffset > originOffset) {
                
                sub = @"ahead of";
            }
            else {
                
                sub = @"behind";
            }

            detail = [NSString stringWithFormat:@"%@ is %.1f hours %@ you.", [TVDatabase flightFromID:self.FlightID].destinationCity, offsetFromOriginToDestination < 0 ? -1 * offsetFromOriginToDestination : offsetFromOriginToDestination, sub];
            
            detail = [detail stringByReplacingOccurrencesOfString:@".0" withString:@""];
            detail = [detail stringByReplacingOccurrencesOfString:@"-" withString:@""];
            detail = [detail stringByReplacingOccurrencesOfString:@"+" withString:@""];
        }
        else {
            
            detail = [NSString stringWithFormat:@"%@ has the same timezone as you.", [TVDatabase flightFromID:self.FlightID].destinationCity];
        }
        
        timezone[@"detail"] = detail;
        
        info[@"timezone"] = timezone;
    }
            
    if (dataType == kTravelDataPlug || dataType == 200) {
        
        NSMutableDictionary *plugs = [NSMutableDictionary dictionaryWithObjectsAndKeys:[self travelData][@"plugs"], @"data", @"Plugs", @"name", @(UITableViewCellAccessoryDisclosureIndicator), @"accessoryType", nil];

        plugs[@"detail"] = [NSString stringWithFormat:@"Plug voltage is %@, frequency %@. Tap for image.", [self travelData][@"plugs"][@"voltage"], [self travelData][@"plugs"][@"frequency"]];
        info[@"plugs"] = plugs;
    }
}

#pragma mark Operational Methods

- (NSString *)generateDate:(NSDate *)date {
 
    return [TVConversions convertDateToString:date withFormat:DAY_MONTH_YEAR];
}

- (IBAction)shareFlight {
 
    NSArray *activityItems = @[[NSString stringWithFormat:@"Going from %@ to %@ on the %@. via Travelog (www.travelogapp.com)", [TVDatabase flightFromID:self.FlightID] .originCity, [TVDatabase flightFromID:self.FlightID] .destinationCity, [TVConversions convertDateToString:[TVDatabase flightFromID:self.FlightID] .date withFormat:DAY_MONTH]]];
 
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
    activityViewController.excludedActivityTypes = @[UIActivityTypePostToWeibo, UIActivityTypeAssignToContact];
 
    [self presentViewController:activityViewController animated:YES completion:NULL];
}

- (IBAction)deleteFlight {
 
    [TVLoadingSignifier signifyLoading:@"Deleting this flight" duration:-1];
 
    [self updateAccount];
}

- (void)updateAccount {
 
    TVAccount *updatedAccount = [TVDatabase currentAccount];
    [[updatedAccount person] deleteFlight:[TVDatabase flightFromID:self.FlightID]];
 
    [TVDatabase updateMyAccount:updatedAccount immediatelyCache:YES withCompletionHandler:^(BOOL success, NSError *error, NSString *callCode) {
 
        if (!error && success) {
 
            [TVNotificationSignifier signifyNotification:@"Deleted the flight" forDuration:3];
 
            [self.navigationController popViewControllerAnimated:YES];
        }
        else {
 
            [self handleError:error andType:callCode];
        }
    }];
}

#pragma mark Initialization

- (void)reloadPeople {
    
    [self.peopleTableView reloadData];
    [self.peopleTableView setNeedsDisplay];
}

- (id)init {
 
    self = [super init];
 
    if (self) {
 
        gridConvert = [[NSMutableDictionary alloc] init];
 
        info = [[NSMutableDictionary alloc] init];
 
        slideNames = [[NSMutableArray alloc] init];
        [slideNames addObject:@"People"];
        [slideNames addObject:@"News"];
        [slideNames addObject:@"Weather"];
        [slideNames addObject:@"Places"];
        
        dispatch_async(dispatch_get_main_queue(), ^{

            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadPeople) name:NSNotificationWroteProfilePicture object:nil];
        });
    }
 
    return self;
}

- (void)setFlightID:(NSString *)_FlightID {
    
    if (![self.FlightID isEqualToString:_FlightID]) {

        FlightID = _FlightID;
        
        [self.travelInfoBanner.scrollView setContentOffset:CGPointMake(0, 0)];
        
        searchedPlaces = [[NSMutableArray alloc] init];
        
        placesIsSearching = NO;
        
        placeDetailViewController = [[TVPlaceDetailViewController alloc] init];
        
        placeFinder = [[TVPlacesQuerySuggestionsRetriever alloc] init];
        
        searchedPlaces = [[NSMutableArray alloc] init];
        
        translationsViewController = [[TVTranslationsViewController alloc] init];
        
    }
    else {
        
    }
    
    [self initializeInfoWithType:200];
}

#pragma mark Swipe Banner

- (void)pollForTravelInfoBanner {

    if (info[@"currency"][@"data"][@"o->d"] && info[@"currency"][@"data"][@"d->o"] && info[@"currency"][@"data"][@"destinationCurrency"] && info[@"currency"][@"data"][@"originCurrency"]) {
        
        [self.travelInfoBanner addTravelInfoTidbit:[NSMutableDictionary dictionaryWithObjectsAndKeys:info[@"currency"][@"detail"], @"body", @"Currency", @"ID", nil]];
    }
    else {
        
        [self.travelInfoBanner removeTravelInfoTidbit:@"Currency"];
    }
    
    if ([info[@"plugs"][@"data"] count]) {

        [self.travelInfoBanner addTravelInfoTidbit:[NSMutableDictionary dictionaryWithObjectsAndKeys:info[@"plugs"][@"detail"], @"body", @"Plugs", @"ID", nil]];
    }
    else {
        
        [self.travelInfoBanner removeTravelInfoTidbit:@"Plugs"];
    }
    
    if ([info[@"languages"][@"data"] count]) {

        [self.travelInfoBanner addTravelInfoTidbit:[NSMutableDictionary dictionaryWithObjectsAndKeys:info[@"languages"][@"detail"], @"body", @"Languages", @"ID", nil]];
    }
    else {
        
        [self.travelInfoBanner removeTravelInfoTidbit:@"Languages"];
    }
    
    if ([info[@"timezone"][@"data"] count]) {
        
        [self.travelInfoBanner addTravelInfoTidbit:[NSMutableDictionary dictionaryWithObjectsAndKeys:info[@"timezone"][@"detail"], @"body", @"Timezone", @"ID", nil]];
    }
    else {
        
        [self.travelInfoBanner removeTravelInfoTidbit:@"Timezone"];
    }
}

#pragma mark Dirty, Funky, Native :I

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    dispatch_async(dispatch_get_main_queue(), ^{

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(travelDataUpdated:) name:[NSString stringWithFormat:@"%@_%@", NSNotificationTravelDataPacketUpdated, self.FlightID] object:nil];
    });
    
    [self pollForTravelInfoBanner];

    [self.newsTableView reloadData];
    [self.newsTableView setNeedsDisplay];
    
    [self.weatherTableView reloadData];
    [self.weatherTableView setNeedsDisplay];
    
    [self.placesTableView reloadData];
    [self.placesTableView setNeedsDisplay];
    
    [self reloadPeople];
    
    pageControl = [[FXPageControl alloc] initWithFrame:CGRectMake(0, self.navigationController.navigationBar.bounds.size.height / 2 + 5, 320.0f, 18.0f)];
    
    [pageControl setBackgroundColor:[UIColor clearColor]];
    
    [pageControl setDotSize:5.0f];
    [pageControl setDotSpacing:5.0f];
    
    [pageControl setNumberOfPages:NUMBER_OF_PAGES];
    [pageControl setSelectedDotColor:[UIColor darkGrayColor]];
    [pageControl setDotColor:[UIColor lightGrayColor]];
    
    [self.navigationController.navigationBar addSubview:pageControl];
}

- (void)viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
    
    dispatch_async(dispatch_get_main_queue(), ^{

        [[NSNotificationCenter defaultCenter] removeObserver:self name:[NSString stringWithFormat:@"%@_%@", NSNotificationTravelDataPacketUpdated, self.FlightID] object:nil];
    });
    
    [pageControl removeFromSuperview];
    pageControl = nil;
    
    [self.searchBar resignFirstResponder];
    
    shouldReloadTravelInfoBanner = NO;
}

- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:YES];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)UIBuffer {

    [[infoScrollView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    [infoScrollView setFrame:CGRectMake(0, 0, 320, self.view.frame.size.height - 88)];
    
    infoScrollView.pagingEnabled = YES;
    infoScrollView.showsHorizontalScrollIndicator = NO;
    infoScrollView.showsVerticalScrollIndicator = NO;
    infoScrollView.scrollsToTop = NO;
    infoScrollView.delegate = self;
    infoScrollView.bounces = NO;
    
    infoScrollView.contentSize = CGSizeMake(infoScrollView.frame.size.width * NUMBER_OF_PAGES, 0);
        
    for (NSInteger i = 0; i <= NUMBER_OF_PAGES - 1; i++) {
        
        NSString *slideName = slideNames[i];
        
        UIView *view = [[NSBundle mainBundle] loadNibNamed:slideName owner:self options:nil][0];
        
        CGRect frame = infoScrollView.frame;
        frame.origin.x = frame.size.width * i;
        frame.origin.y = 0;
        
        view.frame = frame;
        
        [infoScrollView addSubview:view];
    }
    
    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(shareFlight)];
    
    self.navigationItem.rightBarButtonItem = barButtonItem;
    
    for (UIView *subview in self.searchBar.subviews)
    {
        if ([subview isKindOfClass:NSClassFromString(@"UISearchBarBackground")])
            subview.alpha = 0.0;
        
        if ([subview isKindOfClass:NSClassFromString(@"UISegmentedControl")])
            subview.alpha = 0.0;
    }
    
    self.peopleTableView.backgroundColor = [UIColor clearColor];
    
    self.travelInfoBanner = [[TVSwipeBanner alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 103, self.view.frame.size.width, 54)];
    if ([[UIScreen mainScreen] bounds].size.height != 568)     self.travelInfoBanner = [[TVSwipeBanner alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 191, self.view.frame.size.width, 54)];
    [self.view addSubview:self.travelInfoBanner];
    [self.travelInfoBanner setTidbits:[[NSMutableArray alloc] init] andMode:(TVSwipeBannerMode *)kTVSwipeBannerTravelInfo];
    
    if ([[UIScreen mainScreen] bounds].size.height != 568) {
        
        self.peopleTableView.frame = CGRectMake(9, 96, 303, 310);
        self.newsTableView.frame = CGRectMake(self.newsTableView.frame.origin.x, 84, self.newsTableView.frame.size.width, self.newsTableView.frame.size.height - 80);
        self.placesTableView.frame = CGRectMake(self.placesTableView.frame.origin.x, 90, self.placesTableView.frame.size.width, self.placesTableView.frame.size.height - 90);
    }
    else {
        
        self.peopleTableView.frame = CGRectMake(9, 10, 303, 400);
    }
    
    self.navigationItem.title = @"Connections";
}

- (void)viewDidLoad
{
    [self UIBuffer];
    
    dispatch_async(dispatch_get_main_queue(), ^{

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tidbitClicked:) name:@"TidbitClicked" object:nil];
    });
    
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)touchedView {
    
    for (UIView *view in infoScrollView.subviews) {
        
        if ([view isKindOfClass:[UITextField class]] && [view isFirstResponder]) {
            
            [view resignFirstResponder];
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
