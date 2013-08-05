//
//  TrvlogueSettingsViewController.h
//  Trvlogue
//
//  Created by Rohan Kapur on 1/4/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "TrvlogueFindPeopleViewController.h"

@interface TrvlogueSettingsViewController : UIViewController <UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIActionSheetDelegate, UIAlertViewDelegate>
{
    Database *databaseOperator;
    
    IBOutlet UITextField *nameTextField;
    IBOutlet UITextField *emailTextField;
    IBOutlet UITextField *passwordTextField;
    IBOutlet UIImageView *profilePicture;
    IBOutlet UISwitch *pushNotificationEnabled;
    
    BOOL customOrNot;
}

- (IBAction)openCameraOptions;
- (IBAction)deleteAccount;

- (IBAction)logout;

- (IBAction)followers;

@end
