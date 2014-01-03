//
//  TrvlogueFlightRecorderViewController.m
//  Trvlogue
//
//  Created by Rohan Kapur on 17/3/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import "TVFlightRecorderViewController.h"

@interface TVFlightRecorderViewController ()

@end

@implementation TVFlightRecorderViewController

#pragma mark UITextField Methods

- (void)touchedView {
    
    for (UIView *view in self.view.subviews){
        
        if ([view isKindOfClass:[UITextField class]] && [view isFirstResponder]) {
            
            [view resignFirstResponder];
        }
    }
}

- (void)addTextFieldTargets {
    
    [self.originTextField addTarget:self action:@selector(textFieldTextDidChange:) forControlEvents:UIControlEventEditingChanged];
    [self.destinationTextField addTarget:self action:@selector(textFieldTextDidChange:) forControlEvents:UIControlEventEditingChanged];
}

- (void)textFieldDidBeginEditing:(HTAutocompleteTextField *)textField {

    if (autocompletionSuggestion) {
        
        if (textField == self.originTextField) {
            
            self.destinationTextField.text = autocompletionSuggestion[@"short_city_name"];
        }
        else {
            
            self.originTextField.text = autocompletionSuggestion[@"short_city_name"];
        }
    }
    
    autocompletionSuggestion = nil;
    
    if (textField == self.originTextField) {
        
        usingOriginTextField = YES;
    }
    else {
        
        usingOriginTextField = NO;
    }
}

- (BOOL)textFieldShouldReturn:(HTAutocompleteTextField *)textField {
    
    [textField resignFirstResponder];
    
    if (autocompletionSuggestion) {
        
        textField.text = autocompletionSuggestion[@"short_city_name"];
    }
    
    autocompletionSuggestion = nil;
    
    if (textField == self.originTextField) {
        
        [self.destinationTextField becomeFirstResponder];
    }
    
    return YES;
}

- (void)textFieldTextDidChange:(HTAutocompleteTextField *)textField {

    if (autocompletionSuggestion.count) {
        
        NSString *shortCityName = autocompletionSuggestion[@"short_city_name"];
        NSString *longCityName = autocompletionSuggestion[@"city_name"];
        
        if ([[[shortCityName lowercaseString] stringByReplacingOccurrencesOfString:@" " withString:@""] rangeOfString:[[textField.text lowercaseString] stringByReplacingOccurrencesOfString:@" " withString:@""]].location != NSNotFound) {
        }
        else if ([[[[longCityName lowercaseString] stringByReplacingOccurrencesOfString:@" " withString:@""] stringByReplacingOccurrencesOfString:@"," withString:@""] rangeOfString:[[[textField.text lowercaseString] stringByReplacingOccurrencesOfString:@" " withString:@""] stringByReplacingOccurrencesOfString:@"," withString:@""]].location != NSNotFound) {
        }
        else {
                        
            autocompletionSuggestion = nil;
            
            if (textField.text.length) {
                
                [self requestAutocompleteSuggestions:textField.text];
            }
        }
    }
    else {
        
        if (textField.text.length) {
            
            [self requestAutocompleteSuggestions:textField.text];
        }
    }
}

- (NSString *)textField:(HTAutocompleteTextField *)textField completionForPrefix:(NSString *)prefix ignoreCase:(BOOL)ignoreCase {

    NSString *retVal = @"";
    
    if (autocompletionSuggestion) {

        retVal = [autocompletionSuggestion[@"short_city_name"] substringFromIndex:[((NSString *)autocompletionSuggestion[@"short_city_name"]) rangeOfString:prefix options:NSCaseInsensitiveSearch].length];
    }
            
    return retVal;
}

#pragma mark Autocompletion Suggestions Retriever

- (void)initializeAutocompletionObject {
    
    autocompletionSuggestionsRetriever = [[TVAutocompleteSuggestionsRetriever alloc] init];
}

- (void)requestAutocompleteSuggestions:(NSString *)textToSearch {
        
    if ([textToSearch stringByReplacingOccurrencesOfString:@" " withString:@""].length) {
        
        [autocompletionSuggestionsRetriever findLocationAutocompletionSuggestionsBasedOnInput:[textToSearch stringByReplacingOccurrencesOfString:@" " withString:@""] withCompletionHandler:^(NSError *error, BOOL success, NSDictionary *location) {
            
            if (!error && success) {
                
                autocompletionSuggestion = location;
            }
            else {
                
            }
        }];
    }
}

#pragma mark Startup

- (id)init {
    
    if (self = [super init]) {

        self.tabBarItem.title = @"Record";
        self.tabBarItem.image = [UIImage imageNamed:@"record.png"];
        self.navigationItem.title = @"Record Flight";
    }
    
    return self;
}

#pragma mark UI

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    self.datePicker.date = [NSDate date];
}

- (void)UIBuffer {
    
    UIBarButtonItem *submitFlight = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(submitFlight)];
    self.navigationItem.rightBarButtonItem = submitFlight;
        
    for (UIView *view in self.view.subviews) {
        
        if ([view isKindOfClass:[UITextField class]] || [view isKindOfClass:[UITextView class]]) {
            
            view.layer.cornerRadius = 7.0f;
        }
        else if ([view isKindOfClass:[UIDatePicker class]]) {
            
            view.clipsToBounds = YES;
            view.layer.masksToBounds = YES;
            view.layer.cornerRadius = 7.0f;
        }
    }
    
    
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(touchedView)];
    [self.view addGestureRecognizer:gestureRecognizer];
}

#pragma mark Dirty, Funky, Native :D

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    self.originTextField.autocapitalizationType = UITextAutocapitalizationTypeWords;
    self.destinationTextField.autocapitalizationType = UITextAutocapitalizationTypeWords;
    
    self.originTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.destinationTextField.autocorrectionType = UITextAutocorrectionTypeNo;

    self.originTextField.autocompleteDataSource = self;
    self.destinationTextField.autocompleteDataSource = self;

    [self UIBuffer];
    
    [self addTextFieldTargets];
        
    flightParameters = [[NSMutableDictionary alloc] init];
    
    [self initializeAutocompletionObject];
                
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#define key objectForKey:

- (NSString *)originCity {
    
    return flightParameters[@"originCity"];
}

- (NSString *)destinationCity {
    
    return flightParameters[@"destinationCity"];
}

- (NSString *)originCountry {
    
    return flightParameters[@"originCountry"];
}

- (NSString *)destinationCountry {
    
    return flightParameters[@"destinationCountry"];
}

- (double)miles {
    
    return [flightParameters[@"miles"] doubleValue];
}

- (NSDate *)date {
    
    return flightParameters[@"date"];
}

- (NSString *)question {
    
    return flightParameters[@"question"];
}

- (double)originLatitude {
    
    return [flightParameters[@"originLatitude"] doubleValue];
}

- (double)originLongitude {
    
    return [flightParameters[@"originLongitude"] doubleValue];
}

- (double)destinationLatitude {
    
    return [flightParameters[@"destinationLatitude"] doubleValue];
}

- (double)destinationLongitude {
    
    return [flightParameters[@"destinationLongitude"] doubleValue];
}

#pragma mark Subset Mile Handling

- (void)retrieveLocationsWithResponseCallback:(void (^)(NSMutableDictionary *locations))callback {
    
    NSString *origin = [self.originTextField.text copy];
    NSString *destination = [self.destinationTextField.text copy];
    
    TVGoogleGeocoder *geocoder = [[TVGoogleGeocoder alloc] init];
    
    NSMutableDictionary *locations = [[NSMutableDictionary alloc] init];
    
    [geocoder geocodeCityWithName:origin withCompletionHandler:^(NSError *error, BOOL success, NSDictionary *result) {

        if (!error && success) {
            
            if (locations.count) {
                
                locations[@"origin"] = result;

                callback(locations);
            }
            else {
                
                locations[@"origin"] = result;
            }
        }
        else {
            
            [self handleError:error andType:@"record flight"];
        }
    }];
    
    [geocoder geocodeCityWithName:destination withCompletionHandler:^(NSError *error, BOOL success, NSDictionary *result) {

        if (!error && success) {
            
            if (locations.count) {
                
                locations[@"destination"] = result;
                
                callback(locations);
            }
            else {
                
                locations[@"destination"] = result;
            }
        }
        else {
            
            [self handleError:error andType:@"record flight"];
        }
    }];
}

- (void)calculateMiles {
    
    NSDate *date = [[self datePicker].date copy];
    
    __block double calculatedMiles = 0.0;
    
    __block NSMutableDictionary *retrievedLocations = [[NSMutableDictionary alloc] init];
    
    [self retrieveLocationsWithResponseCallback:^(NSMutableDictionary *locations) {

        retrievedLocations = locations;
        
        if ([retrievedLocations count] == 2) {
            
            NSDictionary *originLocation = retrievedLocations[@"origin"];
            NSDictionary *destinationLocation = retrievedLocations[@"destination"];
            
            NSString *originCountry = originLocation[@"country"];
            NSString *destinationCountry = destinationLocation[@"country"];
            
            if ([originCountry isEqualToString:@"The Netherlands"] || [originCountry isEqualToString:@"Holland"]) {
                
                originCountry = @"Netherlands";
            }
            
            if ([destinationCountry isEqualToString:@"The Netherlands"] || [destinationCountry isEqualToString:@"Holland"]) {
                
                destinationCountry = @"Netherlands";
            }
            
            flightParameters[@"date"] = date;

            flightParameters[@"originCity"] = originLocation[@"city"];
            flightParameters[@"destinationCity"] = destinationLocation[@"city"];
            
            flightParameters[@"originCountry"] = originCountry;
            flightParameters[@"destinationCountry"] = destinationCountry;
            
            CLLocation *originCLLocation = [[CLLocation alloc] initWithLatitude:[originLocation[@"coordinate_latitude"] doubleValue] longitude:[originLocation[@"coordinate_longitude"] doubleValue]];
            CLLocation *destinationCLLocation = [[CLLocation alloc] initWithLatitude:[destinationLocation[@"coordinate_latitude"] doubleValue] longitude:[destinationLocation[@"coordinate_longitude"] doubleValue]];

            flightParameters[@"originLatitude"] = @(originCLLocation.coordinate.latitude);
            flightParameters[@"originLongitude"] = @(originCLLocation.coordinate.longitude);
            
            flightParameters[@"destinationLatitude"] = @(destinationCLLocation.coordinate.latitude);
            flightParameters[@"destinationLongitude"] = @(destinationCLLocation.coordinate.longitude);
            
            calculatedMiles = [self convertToMiles:[originCLLocation distanceFromLocation:destinationCLLocation]];
            
            [self calculatedMiles:calculatedMiles];
        }
        else {
            
            [self handleError:nil andType:@"record flight"];
        }
    }];
}

- (double)convertToMiles:(double)meters {
    
    meters /= 1609.34;
    
    return meters;
}

#pragma mark File-Local Error Handling

- (void)handleError:(NSError *)error {
    
    [TVErrorHandler handleError:error];
}

#pragma mark Creating The Flight and Uploading It

- (void)calculatedMiles:(double)miles {
    
    if (miles) {
        
        flightParameters[@"miles"] = @(miles);
        
        [self createTrvlogueFlight];
    }
    else {
        
        NSError *error = [NSError errorWithDomain:@"Invalid miles" code:200 userInfo:@{NSLocalizedDescriptionKey:@"Invalid miles"}];
        
        [self handleError:error];
    }
}

- (NSArray *)incorrectFields {
    
    NSMutableArray *retVal = [[NSMutableArray alloc] init];
    
    [retVal addObjectsFromArray:[self checkIfValuesAreFilled]];
    
    if (retVal.count) {
        
        for (int i = 0; i <= retVal.count - 1; i++) {
            
            if ([[retVal objectAtIndex:i] intValue] == 0) {
                
                [retVal removeObjectAtIndex:i];
            }
        }
    }
    
    return retVal;
}

- (NSMutableArray *)checkIfValuesAreFilled {
    
    NSMutableArray *arrayOfValuesNotFilled = [[NSMutableArray alloc] init];
    
    for (int i = 1; i <= 2; i++) {
        
        for (UIView *view in self.view.subviews) {
            
            if ([view isKindOfClass:[UITextField class]] && view.tag == i) {
                
                if (![((UITextField *)view).text stringByReplacingOccurrencesOfString:@" " withString:@""].length) {
                    
                    [arrayOfValuesNotFilled addObject:@(view.tag)];
                }
            }
        }
    }
    
    return arrayOfValuesNotFilled;
}

- (void)submitFlight {
    
    if (![self incorrectFields].count) {
        
        [self calculateMiles];
        
        [TVLoadingSignifier signifyLoading:@"Recording your flight" duration:-1];
        
        for (int i = 1; i <= 2; i++) {
            
            if ([[self incorrectFields] containsObject:@(i)]) {
                
                [[self.view viewWithTag:i+200] setBackgroundColor:[UIColor colorWithRed:1 green:1 blue:204.0f/255.0f alpha:1.0f]];
            }
            else {
                
                [[self.view viewWithTag:i+200] setBackgroundColor:[UIColor whiteColor]];
            }
        }

        self.originTextField.text = [NSString string];
        self.destinationTextField.text = [NSString string];
    }
    else {
        
        for (int i = 1; i <= 2; i++) {
            
            if ([[self incorrectFields] containsObject:@(i)]) {
                
                [[self.view viewWithTag:i+200] setBackgroundColor:[UIColor colorWithRed:1 green:1 blue:204.0f/255.0f alpha:1.0f]];
            }
            else {
                
                [[self.view viewWithTag:i+200] setBackgroundColor:[UIColor whiteColor]];
            }
        }
    }
}

- (void)createTrvlogueFlight {
    
    TVFlight *trvlogueFlight = [[TVFlight alloc] initWithParameters:flightParameters];
    
    [self insertTrvlogueFlight:trvlogueFlight];
}

- (void)insertTrvlogueFlight:(TVFlight *)trvlogueFlight {

    TVAccount *updatedAccount = [TVDatabase currentAccount];
    [[updatedAccount person] addFlight:trvlogueFlight];

    [TVNotificationSignifier signifyNotification:@"Flight has been recorded" forDuration:3];

    [self updateAccount:updatedAccount];
    
    [trvlogueFlight instantiateTravelData];
    
    dispatch_async(dispatch_get_main_queue(), ^{

        [[NSNotificationCenter defaultCenter] postNotificationName:NSNotificationRecordedNewFlight object:nil userInfo:nil];
    });
}

- (void)updateAccount:(TVAccount *)updatedAccount {
    
    [TVDatabase updateMyAccount:updatedAccount immediatelyCache:YES withCompletionHandler:^(BOOL success, NSError *error, NSString *callCode) {
        
        if (success && !error) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [self.navigationController popViewControllerAnimated:YES];
            });
        }
        else {
            
            [self handleError:error andType:callCode];
        }
    }];
}

- (void)handleError:(NSError *)error andType:(NSString *)type {
    
    [TVErrorHandler handleError:[NSError errorWithDomain:[NSString stringWithFormat:@"Could not %@", type] code:200 userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"Could not %@", type]}]];
}

@end
