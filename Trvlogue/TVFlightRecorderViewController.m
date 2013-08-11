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
        
        retVal = [autocompletionSuggestion[@"short_city_name"] substringFromIndex:[((NSString *)autocompletionSuggestion[@"short_city_name"]) rangeOfString:textField.text options:NSCaseInsensitiveSearch].length];
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

/*
 Where we put our startup methods
 */

#pragma mark UI

- (void)UIBuffer {
    
    UIBarButtonItem *submitFlight = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(submitFlight)];
    self.navigationItem.rightBarButtonItem = submitFlight;
    
    self.datePicker.clipsToBounds = YES;
    self.datePicker.layer.masksToBounds = YES;
    self.datePicker.layer.cornerRadius = 7.0f;
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
    self.originTextField.autocompleteDataSource = self;
    self.destinationTextField.autocompleteDataSource = self;

    [self UIBuffer];
    
    [self addTextFieldTargets];
    
    [TVDatabase isCreatingAnAccount:NO];
    
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

#pragma mark Flight Param Handling and Validation

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

- (BOOL)formValidated {
    
    BOOL retVal;
    
    #define trim stringByReplacingOccurrencesOfString:@" " withString:@""
    
    NSString *origin = [[self originCity] trim];
    NSString *destination = [[self destinationCity] trim];
    double miles = [self miles];
    NSDate *date = [self date];
    CLLocationCoordinate2D originCoordinate = CLLocationCoordinate2DMake([self originLatitude], [self originLongitude]);
    CLLocationCoordinate2D destinationCoordinate = CLLocationCoordinate2DMake([self destinationLatitude], [self destinationLongitude]);
    
    if (origin.length && destination.length && miles && date && CLLocationCoordinate2DIsValid(originCoordinate) && CLLocationCoordinate2DIsValid(destinationCoordinate)) {
        
        retVal = YES;
    }
    else {
        
        retVal = NO;
    }
    
    return retVal;
}

#pragma mark Subset Mile Handling

- (void)retrieveLocationsWithResponseCallback:(void (^)(NSMutableArray *locations))callback {
    
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    
    NSMutableArray *locations = [[NSMutableArray alloc] init];
        
    [geocoder geocodeAddressString:[self originTextField].text completionHandler:^(NSArray *placemarks, NSError *error) {
        
        if (!error) {
            
            [locations addObject:placemarks[0]];
            
            [geocoder geocodeAddressString:[self destinationTextField].text completionHandler:^(NSArray *placemarks, NSError *error) {
                
                [locations addObject:placemarks[0]];
                
                callback(locations);
            }];
        }
        else {
            
            callback(locations);
        }
    }];
}

- (void)calculateMiles {
    
    __block double calculatedMiles = 0.0;
    
    __block NSMutableArray *retrievedLocations = [[NSMutableArray alloc] init];
    
    [self retrieveLocationsWithResponseCallback:^(NSMutableArray *locations) {
        
        retrievedLocations = locations;
        
        if ([retrievedLocations count] == 2) {
            
            CLPlacemark *originLocation = retrievedLocations[0];
            CLPlacemark *destinationLocation = retrievedLocations[1];
            
            NSString *originCountry = originLocation.country;
            NSString *destinationCountry = destinationLocation.country;
            
            if ([originCountry isEqualToString:@"The Netherlands"]) {
                
                originCountry = @"Netherlands";
            }
            
            if ([destinationCountry isEqualToString:@"The Netherlands"]) {
                
                destinationCountry = @"Netherlands";
            }
            
            flightParameters[@"date"] = [self datePicker].date;

            flightParameters[@"originCity"] = !originLocation.locality ? originLocation.administrativeArea : originLocation.locality;
            flightParameters[@"destinationCity"] = !destinationLocation.locality ? destinationLocation.administrativeArea : destinationLocation.locality;
            
            flightParameters[@"originCountry"] = originCountry;
            flightParameters[@"destinationCountry"] = destinationCountry;
            
            flightParameters[@"originLatitude"] = @(originLocation.location.coordinate.latitude);
            flightParameters[@"originLongitude"] = @(originLocation.location.coordinate.longitude);
            
            flightParameters[@"destinationLatitude"] = @(destinationLocation.location.coordinate.latitude);
            flightParameters[@"destinationLongitude"] = @(destinationLocation.location.coordinate.longitude);
            
            calculatedMiles = [self convertToMiles:[originLocation.location distanceFromLocation:destinationLocation.location]];
            
            [self calculatedMiles:calculatedMiles];
        }
        else {
            
            NSError *error = [NSError errorWithDomain:@"Could not geocode locations" code:200 userInfo:@{NSLocalizedDescriptionKey:@"Could not geocode locations"}];
            
            [self handleError:error];
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

- (void)formValidation {
    
    if ([self formValidated]) {
        
        [self createTrvlogueFlight];
    }
    else {
    }
}

- (void)calculatedMiles:(double)miles {
    
    if (miles) {
        
        flightParameters[@"miles"] = @(miles);
        
        [self formValidation];
    }
    else {
        
        NSError *error = [NSError errorWithDomain:@"Invalid miles" code:200 userInfo:@{NSLocalizedDescriptionKey:@"Invalid miles"}];
        
        [self handleError:error];
    }
}

- (void)submitFlight {

    [self calculateMiles];
    
    [TVLoadingSignifier signifyLoading:@"Recording your flight" duration:-1];
}

- (void)createTrvlogueFlight {
    
    TVFlight *trvlogueFlight = [[TVFlight alloc] initWithParameters:flightParameters];
    NSLog(@"%@", trvlogueFlight);
    [self insertTrvlogueFlight:trvlogueFlight];
}

- (void)insertTrvlogueFlight:(TVFlight *)trvlogueFlight {
    
    TVAccount *updatedAccount = [TVDatabase currentAccount];
    [updatedAccount addFlight:trvlogueFlight];
    
    [self updateAccount:updatedAccount];
    
    [trvlogueFlight instantiateTravelData];
}

- (void)updateAccount:(TVAccount *)updatedAccount {
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RecordedFlight" object:nil];
    
    [TVLoadingSignifier signifyLoading:@"Uploading flight" duration:-1];
    
    [TVDatabase updateMyAccount:updatedAccount withCompletionHandler:^(BOOL success, NSError *error, NSString *callCode) {
        
        if (success && !error) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [TVNotificationSignifier signifyNotification:@"Flight has been recorded" forDuration:3];
                
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
