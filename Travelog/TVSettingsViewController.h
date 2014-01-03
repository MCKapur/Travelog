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

@interface TVSettingsViewController : UIViewController <UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIActionSheetDelegate, UIAlertViewDelegate, MFMailComposeViewControllerDelegate>
{
    __weak IBOutlet UITextField *firstNameTextField;
    __weak IBOutlet UITextField *lastNameTextField;
    __weak IBOutlet UITextField *originCityTextField;
    __weak IBOutlet UITextField *jobTextField;
    
    __weak IBOutlet UIImageView *profileImageView;
}

@property (weak, nonatomic) IBOutlet UILabel *linkedInStatus;

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

- (IBAction)exportFlights;
- (IBAction)support;
- (IBAction)logout;
- (IBAction)connectWithLinkedIn:(UIButton *)sender;

- (IBAction)saveData;

@end
