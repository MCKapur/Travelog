//
//  LoginViewController.h
//  Trvlogue
//
//  Created by Rohan Kapur on 23/12/12.
//  Copyright (c) 2012 UWCSEA. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "TVCreateAccountViewController.h"

#import "GIFBackground.h"
#import "TVTextFileLoader.h"

#import "MBFlatAlertView.h"

#import <QuartzCore/QuartzCore.h>

#import "LinkedInDataRetriever.h"
#import "LinkedInAuthorizer.h"

#import "TVAppDelegate.h"

#import "TVDatabase.h"

#import "TVNotificationSignifier.h"

@interface TVLoginViewController : UIViewController <UITextFieldDelegate, UIAlertViewDelegate, UIActionSheetDelegate>
{
    __weak IBOutlet UITextField *emailTextField;
    __weak IBOutlet UITextField *passwordTextField;
    
    __weak IBOutlet UIButton *loginButton;

    __weak IBOutlet UILabel *trvlogueLabel;
    
    UIAlertView *loadingAlert;
    UIActivityIndicatorView *indicatorView;
}

- (IBAction)forgotPass;

- (IBAction)linkedIn;

@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UILabel *trvlogueLabel;
@property (weak, nonatomic) IBOutlet UILabel *loginLabel;

- (IBAction)registerAccount;
- (IBAction)loginAccount;

@property (weak, nonatomic) IBOutlet UIButton *registerAccountBtn;

@end
