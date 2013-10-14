//
//  TrvlogueFlightRecorderViewController.h
//  Trvlogue
//
//  Created by Rohan Kapur on 17/3/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <QuartzCore/QuartzCore.h>

#import "TVAutocompleteSuggestionsRetriever.h"

#import "TVFlightDetailViewController.h"

#import "HTAutocompleteTextField.h"
#import "HTAutocompleteManager.h"

#import "TVGoogleGeocoder.h"

@interface TVFlightRecorderViewController : UIViewController <UITextFieldDelegate,UINavigationControllerDelegate, HTAutocompleteDataSource>
{        
    BOOL usingOriginTextField;
    
    NSDictionary *autocompletionSuggestion;
    
    NSMutableDictionary *flightParameters;
    
    TVAutocompleteSuggestionsRetriever *autocompletionSuggestionsRetriever;
}

@property (strong, nonatomic) IBOutlet HTAutocompleteTextField *originTextField;

@property (strong, nonatomic) IBOutlet HTAutocompleteTextField *destinationTextField;

@property (weak, nonatomic) IBOutlet UIDatePicker *datePicker;

@end
