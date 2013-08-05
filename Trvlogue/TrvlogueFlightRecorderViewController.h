//
//  TrvlogueFlightRecorderViewController.h
//  Trvlogue
//
//  Created by Rohan Kapur on 17/3/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <QuartzCore/QuartzCore.h>

#import "AutocompleteSuggestionsRetriever.h"

#import "TrvlogueFlightDetailViewController.h"

#import "HTAutocompleteTextField.h"
#import "HTAutocompleteManager.h"

@interface TrvlogueFlightRecorderViewController : UIViewController <UITextFieldDelegate,UINavigationControllerDelegate, HTAutocompleteDataSource>
{        
    BOOL usingOriginTextField;
    
    NSDictionary *autocompletionSuggestion;
    
    NSMutableDictionary *flightParameters;
    
    AutocompleteSuggestionsRetriever *autocompletionSuggestionsRetriever;
}

@property (strong, nonatomic) IBOutlet HTAutocompleteTextField *originTextField;

@property (strong, nonatomic) IBOutlet HTAutocompleteTextField *destinationTextField;

@property (strong, nonatomic) IBOutlet UIDatePicker *datePicker;

@end
