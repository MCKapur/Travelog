//
//  TrvlogueSettingsViewController.h
//  Trvlogue
//
//  Created by Rohan Kapur on 1/4/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "TVFindPeopleViewController.h"

#import "TVCreateAccountViewController.h"

@interface TVSettingsViewController : UIViewController <UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIActionSheetDelegate, UIAlertViewDelegate>
{
    TVDatabase *databaseOperator;
    
    __weak IBOutlet UITextField *nameTextField;
    __weak IBOutlet UITextField *emailTextField;
    __weak IBOutlet UITextField *passwordTextField;
    __weak IBOutlet UIImageView *profilePicture;
    __weak IBOutlet UISwitch *pushNotificationEnabled;
    
    BOOL customOrNot;
}

- (IBAction)openCameraOptions;
- (IBAction)deleteAccount;

- (IBAction)logout;

- (IBAction)followers;

@end
