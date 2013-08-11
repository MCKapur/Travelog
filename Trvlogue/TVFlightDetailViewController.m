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

@synthesize FlightID, travelMap, travelInfoBanner, newsTableView, weatherTableView, peopleTableView, weatherTimestamp;

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
            
            TVPerson *person = [self travelData][@"people"][gridNumber];
            
            cell.profilePicture.image = [person getProfilePic];
            cell.name.text = person.name;
            
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
    
    NSLog(@"%i", index);
}

#pragma mark (SUBMARK) UITableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    int retVal = 0;
    
    if (tableView == self.newsTableView) {

        self.newsTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        
        retVal = [[self travelData][@"news"] count];
    }
    else {
        
        self.weatherTableView.separatorStyle = UITableViewCellSeparatorStyleNone;

        retVal = [[self travelData][@"weather"] count];

        NSString *dateStart = [[self travelData][@"weather"] firstObject][@"date"];
        NSString *dateEnd = [[self travelData][@"weather"] lastObject][@"date"];
        
        self.weatherTimestamp.text = [NSString stringWithFormat:@"%@ - %@", [TVConversions convertDateToString:[TVConversions convertStringToDate:dateStart withFormat:YEAR_MONTH_DAY] withFormat:DAY_MONTH], [TVConversions convertDateToString:[TVConversions convertStringToDate:dateEnd withFormat:YEAR_MONTH_DAY] withFormat:DAY_MONTH]];
    }
    
    return retVal;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *CELL_ID = nil;
    
    NSString *NEWS_CELL_ID = @"NewsCell";
    
    NSString *WEATHER_CELL_ID = @"WeatherCell";
    
    if (tableView == self.newsTableView) {
        
        CELL_ID = NEWS_CELL_ID;
    }
    else {
                
        CELL_ID = WEATHER_CELL_ID;
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
    else {
                        
        if (!cell) {
            
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CELL_ID];
            
            cell.textLabel.text = nil;
            cell.detailTextLabel.text = nil;
            cell.imageView.image = nil;
                            
            cell.textLabel.font = [UIFont fontWithName:@"System" size:13.0];
            cell.textLabel.textColor = [UIColor whiteColor];
            
            cell.detailTextLabel.font = [UIFont fontWithName:@"System" size:15.0];
            cell.detailTextLabel.textColor = [UIColor whiteColor];
            
            cell.layer.cornerRadius = 7.0f;
            cell.layer.masksToBounds = YES;
            
            cell.backgroundColor = [UIColor clearColor];
            
            NSDateFormatter *dayFormatter = [[NSDateFormatter alloc] init];
            [dayFormatter setDateFormat:@"EEEE"];
            
            NSString *date = [self travelData][@"weather"][indexPath.row][@"date"];
            
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            cell.textLabel.text = [NSString stringWithFormat:@"%@ will be %@", [dayFormatter stringFromDate:[TVConversions convertStringToDate:date withFormat:YEAR_MONTH_DAY]], [[self travelData][@"weather"][indexPath.row][@"weatherDesc"][0][@"value"] lowercaseString]];
            cell.textLabel.numberOfLines = 2;
            
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%i°F - %i°F", (int)([[self travelData][@"weather"][indexPath.row][@"tempMinF"] doubleValue] + 0.5), (int)([[self travelData][@"weather"][indexPath.row][@"tempMaxF"] doubleValue] + 0.5)];
            
            cell.detailTextLabel.accessibilityLabel = @"F";
            
            cell.imageView.layer.masksToBounds = YES;
            cell.imageView.layer.cornerRadius = 5.0;
            cell.imageView.image = [UIImage imageWithContentsOfFile:[self travelData][@"weather"][indexPath.row][@"imageFilePath"]];
        }
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *CELL_ID = nil;
    
    NSString *NEWS_CELL_ID = @"NewsCell";
    
    NSString *WEATHER_CELL_ID = @"WeatherCell";
    
    if (tableView == self.newsTableView) {
        
        CELL_ID = NEWS_CELL_ID;
    }
    else {
        
        CELL_ID = WEATHER_CELL_ID;
    }
    
    if ([CELL_ID isEqualToString:NEWS_CELL_ID]) {
        
        TVWebViewController *webViewController = [[TVWebViewController alloc] initWithLink:[NSString stringWithFormat:@"http://www.readability.com/m?url=%@",((TVRSSItem *)[self travelData][@"news"][indexPath.row]).link] andTitle:((TVRSSItem *)[self travelData][@"news"][indexPath.row]).title];
        [self.navigationController pushViewController:webViewController animated:YES];
    }
    else {
        
        if ([[tableView cellForRowAtIndexPath:indexPath].detailTextLabel.accessibilityLabel isEqualToString: @"F"]) {
            
            [tableView cellForRowAtIndexPath:indexPath].detailTextLabel.text = [NSString stringWithFormat:@"%i°C - %i°C", (int)([[self travelData][@"weather"][indexPath.row][@"tempMinC"] doubleValue] + 0.5), (int)([[self travelData][@"weather"][indexPath.row][@"tempMaxC"] doubleValue] + 0.5)];
            
            [tableView cellForRowAtIndexPath:indexPath].detailTextLabel.accessibilityLabel = @"C";
        }
        else {
            
            [tableView cellForRowAtIndexPath:indexPath].detailTextLabel.text = [NSString stringWithFormat:@"%i°F - %i°F", (int)([[self travelData][@"weather"][indexPath.row][@"tempMinF"] doubleValue] + 0.5), (int)([[self travelData][@"weather"][indexPath.row][@"tempMaxF"] doubleValue] + 0.5)];
            
            [tableView cellForRowAtIndexPath:indexPath].detailTextLabel.accessibilityLabel = @"F";
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    CGFloat retVal = 0;
    
    if (tableView == self.newsTableView) {
        
        retVal = 65;
    }
    else {
        
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
            
            currency[@"detail"] = [NSString stringWithFormat:@"One %@ is %@ %@", [self travelData][@"currency"][@"originCurrency"], formattedNumber, [self travelData][@"currency"][@"destinationCurrency"]];
        }
        
        info[@"currency"] = currency;
    }
    
    if ([[self travelData][@"languages"] count] || dataType == kTravelDataLanguagesSpoken) {
        
        NSMutableDictionary *languages_ = [NSMutableDictionary dictionaryWithObjectsAndKeys:[self travelData][@"languages"], @"data", @"Languages", @"name", nil];
        
        NSMutableString *detail = [[NSMutableString alloc] init];
        
        for (int i = 0; i <= [[self travelData][@"languages"] count] - 1; i++) {
            
            [detail appendFormat:@"%@", [self travelData][@"languages"][i][@"name"]];
            
            if (i != [[self travelData][@"languages"] count] - 1) {
                
                [detail appendString:@", "];
            }
        }
        
        languages_[@"detail"] = detail;
        
        BOOL hasTranslations = NO;
        
        languages_[@"accessoryType"] = @(UITableViewCellAccessoryNone);
        
        for (NSMutableDictionary *dictionary in [self travelData][@"languages"]) {
            
            if (dictionary[@"translations"]) {
                
                hasTranslations = YES;
                
                break;
            }
        }
        
        if (hasTranslations) {
            
            languages_[@"accessoryType"] = @(UITableViewCellAccessoryDisclosureIndicator);
        }
        
        info[@"languages_"] = languages_;
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
        
        NSString *detail = [NSString stringWithFormat:@"%@ is %@ hours %@ you", [TVDatabase flightFromID:self.FlightID].destinationCity, currentOffset, sub];
        
        detail = [detail stringByReplacingOccurrencesOfString:@".0" withString:@""];
        detail = [detail stringByReplacingOccurrencesOfString:@"-" withString:@""];
        detail = [detail stringByReplacingOccurrencesOfString:@"+" withString:@""];
        
        if ([currentOffset intValue] == 0) {
            
            detail = [NSString stringWithFormat:@"%@ has the same timezone as you", [TVDatabase flightFromID:self.FlightID].destinationCity];
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

/*    if (dataType != 200) {
 
 if ([[self travelData][@"currency"] count] && dataType == kTravelDataCurrency) {
 
 NSMutableDictionary *currency = [NSMutableDictionary dictionaryWithObjectsAndKeys:[self travelData][@"currency"], @"data", @"Currency", @"name", nil];
 
 currency[@"accessoryType"] = @(UITableViewCellAccessoryNone);
 
 if ([self travelData][@"currency"][@"o->d"]) {
 
 NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
 [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
 [formatter setMaximumFractionDigits:2];
 
 NSString *formattedNumber = [formatter stringFromNumber:[self travelData][@"currency"][@"o->d"]];
 
 currency[@"detail"] = [NSString stringWithFormat:@"One %@ is %@ %@", [self travelData][@"currency"][@"originCurrency"], formattedNumber, [self travelData][@"currency"][@"destinationCurrency"]];
 }
 
 info[@"currency"] = currency;
 }
 
 if ([[self travelData][@"languages"] count] && dataType == kTravelDataLanguagesSpoken) {
 
 NSMutableDictionary *languages_ = [NSMutableDictionary dictionaryWithObjectsAndKeys:[self travelData][@"languages"], @"data", @"Languages", @"name", nil];
 
 NSMutableString *detail = [[NSMutableString alloc] init];
 
 for (int i = 0; i <= [[self travelData][@"languages"] count] - 1; i++) {
 
 [detail appendFormat:@"%@", [self travelData][@"languages"][i][@"name"]];
 
 if (i != [[self travelData][@"languages"] count] - 1) {
 
 [detail appendString:@", "];
 }
 }
 
 languages_[@"detail"] = detail;
 
 BOOL hasTranslations = NO;
 
 languages_[@"accessoryType"] = @(UITableViewCellAccessoryNone);
 
 for (NSMutableDictionary *dictionary in [self travelData][@"languages"]) {
 
 if (dictionary[@"translations"]) {
 
 hasTranslations = YES;
 
 break;
 }
 }
 
 if (hasTranslations) {
 
 languages_[@"accessoryType"] = @(UITableViewCellAccessoryDisclosureIndicator);
 }
 
 info[@"languages_"] = languages_;
 }
 
 if ([[self travelData][@"timezone"] count] && dataType == kTravelDataTimezone) {
 
 NSMutableDictionary *timezone = [NSMutableDictionary dictionaryWithObjectsAndKeys:[self travelData][@"timezone"], @"data", @"Timezone", @"name", @(UITableViewCellAccessoryNone), @"accessoryType", nil];
 
 NSString *currentOffset = [self travelData][@"timezone"][@"currentOffsetString"];
 
 NSString *sub = nil;
 
 if ([currentOffset floatValue] > 0) {
 
 sub = @"ahead of";
 }
 else {
 
 sub = @"behind";
 }
 
 NSString *detail = [NSString stringWithFormat:@"%@ is %@ hours %@ you", [TVDatabase flightFromID:self.FlightID] .destinationCity, currentOffset, sub];
 
 detail = [detail stringByReplacingOccurrencesOfString:@".0" withString:@""];
 detail = [detail stringByReplacingOccurrencesOfString:@"-" withString:@""];
 detail = [detail stringByReplacingOccurrencesOfString:@"+" withString:@""];
 
 timezone[@"detail"] = detail;
 
 info[@"timezone"] = timezone;
 }
 
 if ([[self travelData][@"plugs"] count] && dataType == kTravelDataPlug) {
 
 NSMutableDictionary *plugs = [NSMutableDictionary dictionaryWithObjectsAndKeys:[self travelData][@"plugs"], @"data", @"Plugs", @"name", @(UITableViewCellAccessoryDisclosureIndicator), @"accessoryType", nil];
 
 plugs[@"detail"] = [self travelData][@"plugs"][@"plugs"];
 info[@"plugs"] = plugs;
 }
 
 if ([[self travelData][@"facts"] count] && dataType == kTravelDataFacts) {
 
 NSMutableDictionary *facts = [NSMutableDictionary dictionaryWithObjectsAndKeys:[self travelData][@"facts"], @"data", @"Fun Facts", @"name", @(UITableViewCellAccessoryDisclosureIndicator), @"accessoryType", nil];
 
 facts[@"detail"] = [self travelData][@"facts"][0];
 
 info[@"facts"] = facts;
 }
 }
 else {
 
 if ([[self travelData][@"currency"] count]) {
 
 NSMutableDictionary *currency = [NSMutableDictionary dictionaryWithObjectsAndKeys:[self travelData][@"currency"], @"data", @"Currency", @"name", nil];
 
 currency[@"accessoryType"] = @(UITableViewCellAccessoryNone);
 
 if ([self travelData][@"currency"][@"o->d"]) {
 
 NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
 [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
 [formatter setMaximumFractionDigits:2];
 
 NSString *formattedNumber = [formatter stringFromNumber:[self travelData][@"currency"][@"o->d"]];
 
 currency[@"detail"] = [NSString stringWithFormat:@"One %@ is %@ %@", [self travelData][@"currency"][@"originCurrency"], formattedNumber, [self travelData][@"currency"][@"destinationCurrency"]];
 }
 
 info[@"currency"] = currency;
 }
 
 if ([[self travelData][@"languages"] count]) {
 
 NSMutableDictionary *languages = [NSMutableDictionary dictionaryWithObjectsAndKeys:[self travelData][@"languages"], @"data", @"Languages", @"name", nil];
 
 NSMutableString *detail = [[NSMutableString alloc] init];
 
 for (int i = 0; i <= [[self travelData][@"languages"] count] - 1; i++) {
 
 [detail appendFormat:@"%@", [self travelData][@"languages"][i][@"name"]];
 
 if (i != [[self travelData][@"languages"] count] - 1) {
 
 [detail appendString:@", "];
 }
 }
 
 languages[@"detail"] = detail;
 
 BOOL hasTranslations = NO;
 
 languages[@"accessoryType"] = @(UITableViewCellAccessoryNone);
 
 for (NSMutableDictionary *dictionary in [self travelData][@"languages"]) {
 
 if (dictionary[@"translations"]) {
 
 hasTranslations = YES;
 
 break;
 }
 }
 
 if (hasTranslations) {
 
 languages[@"accessoryType"] = @(UITableViewCellAccessoryDisclosureIndicator);
 }
 
 info[@"languages"] = languages;
 }
 
 if ([[self travelData][@"timezone"] count]) {
 
 NSMutableDictionary *timezone = [NSMutableDictionary dictionaryWithObjectsAndKeys:[self travelData][@"timezone"], @"data", @"Timezone", @"name", @(UITableViewCellAccessoryNone), @"accessoryType", nil];
 
 NSString *currentOffset = [self travelData][@"timezone"][@"currentOffsetString"];
 
 NSString *sub = nil;
 
 if ([currentOffset floatValue] > 0) {
 
 sub = @"ahead of";
 }
 else {
 
 sub = @"behind";
 }
 
 NSString *detail = [NSString stringWithFormat:@"%@ is %@ hours %@ you", [TVDatabase flightFromID:self.FlightID] .destinationCity, currentOffset, sub];
 
 detail = [detail stringByReplacingOccurrencesOfString:@".0" withString:@""];
 detail = [detail stringByReplacingOccurrencesOfString:@"-" withString:@""];
 detail = [detail stringByReplacingOccurrencesOfString:@"+" withString:@""];
 
 timezone[@"detail"] = detail;
 
 info[@"timezone"] = timezone;
 }
 
 if ([[self travelData][@"plugs"] count]) {
 
 NSMutableDictionary *plugs = [NSMutableDictionary dictionaryWithObjectsAndKeys:[self travelData][@"plugs"], @"data", @"Plugs", @"name", @(UITableViewCellAccessoryDisclosureIndicator), @"accessoryType", nil];
 
 plugs[@"detail"] = [self travelData][@"plugs"][@"plugs"];
 info[@"plugs"] = plugs;
 }
 
 if ([[self travelData][@"facts"] count] && dataType == kTravelDataFacts) {
 
 NSMutableDictionary *facts = [NSMutableDictionary dictionaryWithObjectsAndKeys:[self travelData][@"facts"], @"data", @"Fun Facts", @"name", @(UITableViewCellAccessoryDisclosureIndicator), @"accessoryType", nil];
 
 facts[@"detail"] = [self travelData][@"facts"][0];
 
 info[@"facts"] = facts;
 }
 }
*/

#pragma mark Map Methods

- (void)updateMap {
 
    [self.travelMap setRegion:MKCoordinateRegionMakeWithDistance([TVDatabase flightFromID:self.FlightID].destinationCoordinate, 10000, 10000)];
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
    [updatedAccount deleteFlight:[TVDatabase flightFromID:self.FlightID]];
 
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
        [slideNames addObject:@"Places"];
        [slideNames addObject:@"Weather"];
 
        slideCount = 1;
    }
 
    return self;
}

- (id)initWithTrvlogueFlightID:(NSString *)_FlightID {
 
    self = [self init];
    
    if (self) {
        
        self.FlightID = _FlightID;
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, (unsigned long)NULL), ^{
            
            [self initializeInfoWithType:200];
        });
    }
    
    return self;
}


- (void)setFlightID:(NSString *)_FlightID {
    
    FlightID = _FlightID;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, (unsigned long)NULL), ^{
        
        [self initializeInfoWithType:200];
    });
}

#pragma mark Swipe Banner

- (void)pollForTravelInfoBanner {
    
    if ([info[@"currency"] count]) {
        
        [self.travelInfoBanner addTravelInfoTidbit:[NSMutableDictionary dictionaryWithObjectsAndKeys:info[@"currency"][@"detail"], @"body", @"Currency", @"ID", nil]];
    }
    
    if ([info[@"plugs"] count]) {
        
        [self.travelInfoBanner addTravelInfoTidbit:[NSMutableDictionary dictionaryWithObjectsAndKeys:info[@"plugs"][@"detail"], @"body", @"Plugs", @"ID", nil]];
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
    
    [super viewWillAppear:YES];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(travelDataUpdated:) name:[NSString stringWithFormat:@"TravelDataUpdated_%@", self.FlightID] object:nil];
    
    [TVDatabase isCreatingAnAccount:NO];
    
    [self.newsTableView reloadData];
    [self.newsTableView setNeedsDisplay];
    
    [self.peopleTableView reloadData];
    [self.peopleTableView setNeedsDisplay];
    
    [self.weatherTableView reloadData];
    [self.weatherTableView setNeedsDisplay];
    
    [self updateMap];
}

- (void)viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:[NSString stringWithFormat:@"TravelDataUpdated_%@", self.FlightID] object:nil];
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

    [self addBanner];
}

- (void)viewDidLoad
{    
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
