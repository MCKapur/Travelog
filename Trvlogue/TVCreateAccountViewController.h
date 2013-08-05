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
    IBOutlet UITextField *nameTextField;
    IBOutlet UITextField *originCityTextField;
    IBOutlet UITextField *jobTextField;

    TVDatabase *databaseOperator;
            
    TVAccount *account;
    NSMutableArray *followingArray;
        
    IBOutlet GIFBackground *gifImage;

    IBOutlet UIImageView *profileImageView;
    
    NSDictionary *presetData;
}

- (IBAction)openCameraOptions;

@property (nonatomic, strong) NSMutableDictionary *accountDict;

- (id)initWithPresetData:(NSDictionary *)data withAccessToken:(NSString *)accessToken andLinkedInId:(NSString *)linkedInId;

- (id)initWithEmail:(NSString *)email andPassword:(NSString *)password;

@end
