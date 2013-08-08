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
#import "TVTextFileLoader.h"

#import <AddressBook/AddressBook.h>
#import <CoreLocation/CoreLocation.h>

#import "TVViewController.h"

#import "MBAlertView.h"

#import <QuartzCore/QuartzCore.h>

@interface TVCreateAccountViewController : UIViewController <UITextFieldDelegate, UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
{
    __weak IBOutlet UITextField *firstNameTextField;
    __weak IBOutlet UITextField *lastNameTextField;
    __weak IBOutlet UITextField *originCityTextField;
    __weak IBOutlet UITextField *jobTextField;
    
    TVAccount *account;
    NSMutableArray *followingArray;
        
    __strong IBOutlet GIFBackground *gifImage;

    __weak IBOutlet UIImageView *profileImageView;
    
    NSDictionary *presetData;
}

- (IBAction)openCameraOptions;

@property (nonatomic, strong) NSMutableDictionary *accountDict;

- (id)initWithPresetData:(NSDictionary *)data withAccessToken:(NSString *)accessToken andLinkedInId:(NSString *)linkedInId;

- (id)initWithEmail:(NSString *)email andPassword:(NSString *)password;

@end
