//
//  LoginViewController.h
//  Trvlogue
//
//  Created by Rohan Kapur on 23/12/12.
//  Copyright (c) 2012 UWCSEA. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "TrvlogueCreateAccountViewController.h"

#import "GIFBackground.h"
#import "TextFileLoader.h"

#import "MBAlertView.h"

#import <QuartzCore/QuartzCore.h>

#import "LinkedInDataRetriever.h"
#import "LinkedInAuthorizer.h"

#import "TrvlogueAppDelegate.h"

@interface TrvlogueLoginViewController : UIViewController <UITextFieldDelegate, UIAlertViewDelegate, UIActionSheetDelegate>
{
    IBOutlet UITextField *emailTextField;
    IBOutlet UITextField *passwordTextField;
    
    IBOutlet UILabel *trvlogueLabel;
    
    IBOutlet GIFBackground *gifImage;
        
    Database *databaseOperator;
    
    UIAlertView *loadingAlert;
    UIActivityIndicatorView *indicatorView;
}

- (IBAction)forgotPass;

- (IBAction)linkedIn;

@property (strong, nonatomic) IBOutlet UIButton *loginButton;
@property (strong, nonatomic) IBOutlet UILabel *trvlogueLabel;
@property (strong, nonatomic) IBOutlet UILabel *loginLabel;

- (IBAction)registerAccount;
- (IBAction)loginAccount;

@property (strong, nonatomic) IBOutlet UIButton *registerAccountBtn;

@end
