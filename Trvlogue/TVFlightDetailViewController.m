//
//  TrvlogueFlightDetailViewController.m
//  Trvlogue
//
//  Created by Rohan Kapur on 23/3/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#define NUMBER_OF_SLIDES 4

#import "TVFlightDetailViewController.h"

@interface TVFlightDetailViewController ()

@end

@implementation TVFlightDetailViewController
@synthesize FlightID, travelInfoBanner, peopleTableView;

- (void)handleError:(NSError *)error andType:(NSString *)type {
    
    [TVErrorHandler handleError:[NSError errorWithDomain:[NSString stringWithFormat:@"Could not %@", type] code:200 userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"Could not %@", type]}]];
}

#pragma mark TravelData

- (NSMutableDictionary *)travelData {

    return [TVDatabase travelDataPacketWithID:self.FlightID];
}

- (IBAction)changedSegmentedControl:(UISegmentedControl *)sender {
}

- (void)tidbitClicked:(NSNotification *)notification {
    
    if ([notification.userInfo[@"ID"] isEqualToString:@"Plugs"]) {
        
    }
}

#pragma mark TrvlogueFlight-TravelData Delegate

- (void)travelDataUpdated:(NSNotification *)notification {
    
    TravelDataTypes *dataType = (TravelDataTypes *)[notification.userInfo[@"dataType"] intValue];

    [self initializeInfoWithType:(int)dataType];
    
    if ((int)dataType == kTravelDataPeople) {
        
        [self.peopleTableView reloadData];
        [self.peopleTableView setNeedsDisplay];
    }
    else if ((int)dataType == kTravelDataCurrentNews) {

        [self.newsTableView reloadData];
        [self.newsTableView setNeedsDisplay];
    }
    else if ((int)dataType == kTravelDataWeather) {

        [self.weatherTableView reloadData];
        [self.weatherTableView setNeedsDisplay];
    }
    
    [self pollForTravelInfoBanner];
}

#pragma mark UISearchBar Delegate Methods

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    
    [searchBar resignFirstResponder];
    
    [self reloadPlacesData];
}

#pragma mark Places Methods

- (void)reloadPlacesData {
    
    if ([[[self.searchBar text] stringByReplacingOccurrencesOfString:@" " withString:@""] length]) {

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, (unsigned long)NULL), ^{
            
            [places removeAllObjects];
            
            [placeFinder findPlacesBasedOnInput:[NSString stringWithFormat:@"%@ in %@, %@", self.searchBar.text, [TVDatabase flightFromID:self.FlightID].destinationCity, [TVDatabase flightFromID:self.FlightID].destinationCountry] withCompletionHandler:^(NSError *error, NSMutableArray *_places) {

                [places addObjectsFromArray:_places];
                
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

- (CGFloat)gridView:(UIGridView *)grid widthForColumnAt:(int)columnIndex
{
	return (float)320/3;
}

- (CGFloat)gridView:(UIGridView *)grid heightForRowAt:(int)rowIndex
{             
	return 102.5;
}

- (NSInteger)numberOfColumnsOfGridView:(UIGridView *)grid
{
	return 3;
}

- (NSInteger)numberOfCellsOfGridView:(UIGridView *)grid
{
    int retVal = [[self travelData][@"people"] count];
    
	return retVal;
}

- (UIGridViewCell *)gridView:(UIGridView *)grid cellForRowAt:(int)rowIndex AndColumnAt:(int)columnIndex
{
    if (!rowIndex && !columnIndex) {
        
        gridNumber = 0;
        [gridConvert removeAllObjects];
    }
        
	TVPersonCell *cell = (TVPersonCell *)[grid dequeueReusableCell];
	
	if (!cell) {
        
		cell = [[TVPersonCell alloc] init];
        
        if (cell) {
            
            TVAccount *account = [self travelData][@"people"][gridNumber];
            
            cell.profilePicture.image = [TVDatabase locateProfilePictureOnDiskWithUserId:account.userId];
            cell.name.text = account.person.name;
            
            gridConvert[[NSString stringWithFormat:@"(%i,%i)", rowIndex, columnIndex]] = @(gridNumber);
            gridNumber++;
        }
    }
        
	return cell;
}

- (void)gridView:(UIGridView *)grid didSelectRowAt:(int)rowIndex AndColumnAt:(int)colIndex
{
	NSString *coordinate = [NSString stringWithFormat:@"(%i,%i)", rowIndex, colIndex];
    
    int index = [gridConvert[coordinate] intValue];

    TVAccount *account = [self travelData][@"people"][index];
    
    TVMessageDetailViewController *messageDetailViewController;
    
    if ([TVDatabase messageHistoryIDFromRecipients:[[NSMutableArray alloc] initWithObjects:account.userId, [TVDatabase currentAccount].userId, nil]]) {

        messageDetailViewController = [[TVMessageDetailViewController alloc] initWithMessageHistoryID:[TVDatabase messageHistoryIDFromRecipients:[[NSMutableArray alloc] initWithObjects:account.userId, [TVDatabase currentAccount].userId, nil]]];
    }
    else {
        
        TVMessageHistory *messageHistory = [[TVMessageHistory alloc] initWithSenderId:[[TVDatabase currentAccount] userId] andReceiverId:account.userId andMessages:[[NSMutableArray alloc] init]];
        
        TVAccount *newAccount = [TVDatabase currentAccount];
        [newAccount.person.messageHistories addObject:messageHistory];

        [TVDatabase updateMyCache:newAccount];

        messageDetailViewController = [[TVMessageDetailViewController alloc] initWithMessageHistoryID:messageHistory.ID];
    }

    [self.navigationController pushViewController:messageDetailViewController animated:YES];
}

#pragma mark (SUBMARK) UITableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    int retVal = 0;
    
    if (tableView == self.newsTableView) {

        self.newsTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        
        retVal = [[self travelData][@"news"] count];
    }
    else if (tableView == self.weatherTableView) {
        
        self.weatherTableView.separatorStyle = UITableViewCellSeparatorStyleNone;

        retVal = [[self travelData][@"weather"] count];

        NSString *dateStart = [[self travelData][@"weather"] firstObject][@"date"];
        NSString *dateEnd = [[self travelData][@"weather"] lastObject][@"date"];
        
        self.weatherTimestamp.text = [NSString stringWithFormat:@"%@ - %@", [TVConversions convertDateToString:[TVConversions convertStringToDate:dateStart withFormat:YEAR_MONTH_DAY] withFormat:DAY_MONTH], [TVConversions convertDateToString:[TVConversions convertStringToDate:dateEnd withFormat:YEAR_MONTH_DAY] withFormat:DAY_MONTH]];
    }
    else if (tableView == self.placesTableView) {
        
        retVal = places.count;
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
                                    
        if (cell == nil) {
                
            NSArray *views = [[NSBundle mainBundle] loadNibNamed:@"TVNewsCell" owner:self options:nil];
                
            for (UIView *view in views) {
                    
                if ([view isKindOfClass:[UITableViewCell class]])
                {
                    cell = (TVNewsCell *)view;
                }
            }
            
            ((TVNewsCell *)cell).title.text = ((TVRSSItem *)[self travelData][@"news"][indexPath.row]).title;
        }
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
                        
            cell.detailTextLabel.accessibilityLabel = @"F";
            
            cell.imageView.layer.masksToBounds = YES;
            cell.imageView.layer.cornerRadius = 5.0;
        }
        
        NSDateFormatter *dayFormatter = [[NSDateFormatter alloc] init];
        [dayFormatter setDateFormat:@"EEEE"];
        NSString *date = [self travelData][@"weather"][indexPath.row][@"date"];
        
        cell.textLabel.text = [NSString stringWithFormat:@"%@ will be %@", [dayFormatter stringFromDate:[TVConversions convertStringToDate:date withFormat:YEAR_MONTH_DAY]], [[self travelData][@"weather"][indexPath.row][@"weatherDesc"][0][@"value"] lowercaseString]];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%i°F - %i°F", (int)([[self travelData][@"weather"][indexPath.row][@"tempMinF"] doubleValue] + 0.5), (int)([[self travelData][@"weather"][indexPath.row][@"tempMaxF"] doubleValue] + 0.5)];
        cell.imageView.image = [UIImage imageWithContentsOfFile:[self travelData][@"weather"][indexPath.row][@"imageFilePath"]];
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
        
        TVGooglePlace *place = places[indexPath.row];

        cell.textLabel.text = [NSString stringWithFormat:@"%@", place.name];
        
        NSMutableString *detail = [[NSMutableString alloc] init];
        
        if (place.rating) {
            
            [detail appendFormat:@"%.1f/5 · ", place.rating];
        }
        
        if (place.priceLevel) {
            
            for (int i = 1; i <= place.priceLevel; i++) {
                
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
        
        TVWebViewController *webViewController = [[TVWebViewController alloc] initWithLink:[NSString stringWithFormat:@"http://www.readability.com/m?url=%@",((TVRSSItem *)[self travelData][@"news"][indexPath.row]).link] andTitle:((TVRSSItem *)[self travelData][@"news"][indexPath.row]).title];
        [self.navigationController pushViewController:webViewController animated:YES];
    }
    else if ([CELL_ID isEqualToString:WEATHER_CELL_ID]) {
    
        if ([[tableView cellForRowAtIndexPath:indexPath].detailTextLabel.accessibilityLabel isEqualToString: @"F"]) {

            [tableView cellForRowAtIndexPath:indexPath].detailTextLabel.text = [NSString stringWithFormat:@"%i°C - %i°C", (int)([[self travelData][@"weather"][indexPath.row][@"tempMinC"] doubleValue] + 0.5), (int)([[self travelData][@"weather"][indexPath.row][@"tempMaxC"] doubleValue] + 0.5)];
            
            [tableView cellForRowAtIndexPath:indexPath].detailTextLabel.accessibilityLabel = @"C";
        }
        else {

            [tableView cellForRowAtIndexPath:indexPath].detailTextLabel.text = [NSString stringWithFormat:@"%i°F - %i°F", (int)([[self travelData][@"weather"][indexPath.row][@"tempMinF"] doubleValue] + 0.5), (int)([[self travelData][@"weather"][indexPath.row][@"tempMaxF"] doubleValue] + 0.5)];
            
            [tableView cellForRowAtIndexPath:indexPath].detailTextLabel.accessibilityLabel = @"F";
        }
    }
    else {
        
        [placeDetailViewController setPlace:places[indexPath.row]];
        
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
    
    CGFloat pageWidth = sender.frame.size.width;
    int page = floor((sender.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    
    if (page > slideCount - 1) {
        
        slideCount++;
    }
    else if (page < slideCount - 1) {
        
        slideCount--;
    }
    
    infoSegControl.selectedSegmentIndex = slideCount - 1;
}

#pragma mark Info Updates

- (void)initializeInfoWithType:(int)dataType {

    if ([[self travelData][@"currency"] count] || dataType == kTravelDataCurrency) {
        
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
    
    if ([[self travelData][@"languages"] count] || dataType == kTravelDataLanguagesSpoken) {
        
        NSMutableDictionary *languages_ = [NSMutableDictionary dictionaryWithObjectsAndKeys:[self travelData][@"languages"], @"data", @"Languages", @"name", nil];
        
        NSMutableString *detail = [[NSMutableString alloc] init];
        
        for (int i = 0; i <= [[self travelData][@"languages"] count] - 1; i++) {
            
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
            
            [languages_[@"detail"] appendString:@" Click for translations."];
        }
        
        info[@"languages"] = languages_;
    }
    
    if ([[self travelData][@"timezone"] count] || dataType == kTravelDataTimezone) {
        
        NSMutableDictionary *timezone = [NSMutableDictionary dictionaryWithObjectsAndKeys:[self travelData][@"timezone"], @"data", @"Timezone", @"name", @(UITableViewCellAccessoryNone), @"accessoryType", nil];
        
        NSString *currentOffset = [self travelData][@"timezone"][@"currentOffsetString"];
        
        NSString *sub = nil;
        
        if ([currentOffset floatValue] > 0) {
            
            sub = @"ahead of";
        }
        else {
            
            sub = @"behind";
        }
        
        NSString *detail = [NSString stringWithFormat:@"%@ is %@ hours %@ you.", [TVDatabase flightFromID:self.FlightID].destinationCity, currentOffset, sub];
        
        detail = [detail stringByReplacingOccurrencesOfString:@".0" withString:@""];
        detail = [detail stringByReplacingOccurrencesOfString:@"-" withString:@""];
        detail = [detail stringByReplacingOccurrencesOfString:@"+" withString:@""];
        
        if ([currentOffset intValue] == 0) {
            
            detail = [NSString stringWithFormat:@"%@ has the same timezone as you.", [TVDatabase flightFromID:self.FlightID].destinationCity];
        }
        
        timezone[@"detail"] = detail;
        
        info[@"timezone"] = timezone;
    }
            
    if ([[self travelData][@"plugs"] count] || dataType == kTravelDataPlug) {
        
        NSMutableDictionary *plugs = [NSMutableDictionary dictionaryWithObjectsAndKeys:[self travelData][@"plugs"], @"data", @"Plugs", @"name", @(UITableViewCellAccessoryDisclosureIndicator), @"accessoryType", nil];

        plugs[@"detail"] = [NSString stringWithFormat:@"The plug socket voltage is %@ and frequency %@. Click for image.", [self travelData][@"plugs"][@"voltage"], [self travelData][@"plugs"][@"frequency"]];
        info[@"plugs"] = plugs;
    }
    
    if ([[self travelData][@"facts"] count] || dataType == kTravelDataFacts) {
        
        NSMutableDictionary *facts = [NSMutableDictionary dictionaryWithObjectsAndKeys:[self travelData][@"facts"], @"data", @"Fun Facts", @"name", @(UITableViewCellAccessoryDisclosureIndicator), @"accessoryType", nil];
        
        facts[@"detail"] = [self travelData][@"facts"][0];
        
        info[@"facts"] = facts;
    }
}

#pragma mark Operational Methods

- (NSString *)generateDate:(NSDate *)date {
 
    return [TVConversions convertDateToString:date withFormat:DAY_MONTH_YEAR];
}

- (IBAction)shareFlight {
 
    NSArray *activityItems = @[[NSString stringWithFormat:@"Going from %@ to %@ on the %@. What about you?", [TVDatabase flightFromID:self.FlightID] .originCity, [TVDatabase flightFromID:self.FlightID] .destinationCity, [TVConversions convertDateToString:[TVDatabase flightFromID:self.FlightID] .date withFormat:DAY_MONTH]]];
 
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
 
    [TVDatabase updateMyAccount:updatedAccount withCompletionHandler:^(BOOL success, NSError *error, NSString *callCode) {
 
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
 
        slideCount = 1;
    }
 
    return self;
}

- (id)initWithTrvlogueFlightID:(NSString *)_FlightID {
 
    self = [self init];
    
    if (self) {
        
        self.FlightID = _FlightID;
        
        [self initializeInfoWithType:200];
    }
    
    return self;
}

- (void)setFlightID:(NSString *)_FlightID {
    
    if (![self.FlightID isEqualToString:_FlightID]) {

        FlightID = _FlightID;
        
        places = [[NSMutableArray alloc] init];
    }
        
    [self initializeInfoWithType:200];
    
    [self.travelInfoBanner removeTravelInfoTidbits];
    
    [self pollForTravelInfoBanner];
}

#pragma mark Swipe Banner

- (void)pollForTravelInfoBanner {

    if ([info[@"currency"] count]) {
        
        [self.travelInfoBanner addTravelInfoTidbit:[NSMutableDictionary dictionaryWithObjectsAndKeys:info[@"currency"][@"detail"], @"body", @"Currency", @"ID", nil]];
    }
    
    if ([info[@"plugs"] count]) {

        [self.travelInfoBanner addTravelInfoTidbit:[NSMutableDictionary dictionaryWithObjectsAndKeys:info[@"plugs"][@"detail"], @"body", @"Plugs", @"ID", nil]];
    }
    
    if ([info[@"languages"] count]) {

        [self.travelInfoBanner addTravelInfoTidbit:[NSMutableDictionary dictionaryWithObjectsAndKeys:info[@"languages"][@"detail"], @"body", @"Languages", @"ID", nil]];
    }
    
    if ([info[@"timezone"] count]) {
        
        [self.travelInfoBanner addTravelInfoTidbit:[NSMutableDictionary dictionaryWithObjectsAndKeys:info[@"timezone"][@"detail"], @"body", @"Timezone", @"ID", nil]];
    }
}

- (void)addBanner {

    self.travelInfoBanner = [[TVSwipeBanner alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 96, self.view.frame.size.width, 52)];
    [self.view addSubview:self.travelInfoBanner];
    [self.travelInfoBanner setTidbits:[NSMutableArray array] andMode:(TVSwipeBannerMode *)kTVSwipeBannerTravelInfo];
        
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tidbitClicked:) name:[NSString stringWithFormat:@"TidbitClicked"] object:nil];
    
    [self pollForTravelInfoBanner];
}

#pragma mark Dirty, Funky, Native :I

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(travelDataUpdated:) name:[NSString stringWithFormat:@"TravelDataUpdated_%@", self.FlightID] object:nil];
        
    [self.newsTableView reloadData];
    [self.newsTableView setNeedsDisplay];
    
    [self.peopleTableView reloadData];
    [self.peopleTableView setNeedsDisplay];

    [self.weatherTableView reloadData];
    [self.weatherTableView setNeedsDisplay];
    
    [self.placesTableView reloadData];
    [self.placesTableView setNeedsDisplay];
}

- (void)viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:[NSString stringWithFormat:@"TravelDataUpdated_%@", self.FlightID] object:nil];
    
    [self.searchBar resignFirstResponder];
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
    
    self.navigationItem.title = [[TVDatabase flightFromID:self.FlightID] destinationCity];
    
    infoScrollView.pagingEnabled = YES;
    infoScrollView.showsHorizontalScrollIndicator = NO;
    infoScrollView.showsVerticalScrollIndicator = NO;
    infoScrollView.scrollsToTop = NO;
    infoScrollView.delegate = self;
    infoScrollView.bounces = NO;
    
    infoScrollView.contentSize = CGSizeMake(infoScrollView.frame.size.width * NUMBER_OF_SLIDES, infoScrollView.frame.size.height);
    
    for (int i = 0; i <= NUMBER_OF_SLIDES - 1; i++) {
        
        NSString *slideName = slideNames[i];
        
        UIView *view = [[NSBundle mainBundle] loadNibNamed:slideName owner:self options:nil][0];
        
        CGRect frame = infoScrollView.frame;
        frame.origin.x = frame.size.width * i;
        frame.origin.y = 0;
        
        view.frame = frame;
        
        [infoScrollView addSubview:view];
    }
    
    [self.view addSubview:infoView];
    
    [infoView setFrame:CGRectMake(0, 0, infoView.frame.size.width, infoView.frame.size.height)];
    
    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(shareFlight)];
    
    self.navigationItem.rightBarButtonItem = barButtonItem;
    
    infoSegControl.selectedSegmentIndex = slideCount - 1;
    
    for (UIView * subview in self.searchBar.subviews)
    {
        if ([subview isKindOfClass:NSClassFromString(@"UISearchBarBackground")])
            subview.alpha = 0.0;
        
        if ([subview isKindOfClass:NSClassFromString(@"UISegmentedControl")])
            subview.alpha = 0.0;
    }
    
    self.peopleTableView.backgroundColor = [UIColor clearColor];

    [self addBanner];
}

- (void)viewDidLoad
{
    placeDetailViewController = [[TVPlaceDetailViewController alloc] init];
    
    placeFinder = [[TVPlacesQuerySuggestionsRetriever alloc] init];
    
    places = [[NSMutableArray alloc] init];
    
    [self UIBuffer];

    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
