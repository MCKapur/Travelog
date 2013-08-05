//
//  CreateAccountViewController.h
//  Trvlogue
//
//  Created by Rohan Kapur on 23/12/12.
//  Copyright (c) 2012 UWCSEA. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <CoreLocation/CoreLocation.h>

#import "GIFBackground.h"
#import "TextFileLoader.h"

#import <AddressBook/AddressBook.h>
#import <CoreLocation/CoreLocation.h>

#import "TrvlogueViewController.h"

#import "MBAlertView.h"

#import <QuartzCore/QuartzCore.h>

@interface TrvlogueCreateAccountViewController : UIViewController <UITextFieldDelegate, UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
{
    IBOutlet UITextField *passwordTextField;
    IBOutlet UITextField *emailTextField;
    IBOutlet UITextField *nameTextField;
    IBOutlet UITextField *originCityTextField;
    IBOutlet UITextField *jobTextField;

    Database *databaseOperator;
            
    TrvlogueAccount *account;
    NSMutableArray *followingArray;
        
    IBOutlet GIFBackground *gifImage;

    IBOutlet UIImageView *profileImageView;
    
    NSDictionary *presetData;
}

- (IBAction)openCameraOptions;
- (IBAction)registerAction;

@property (nonatomic, strong) NSMutableDictionary *accountDict;

- (id)initWithPresetData:(NSDictionary *)data withAccessToken:(NSString *)accessToken andLinkedInId:(NSString *)linkedInId;

@end
