//
//  LoginViewController.m
//  Trvlogue
//
//  Created by Rohan Kapur on 23/12/12.
//  Copyright (c) 2012 UWCSEA. All rights reserved.
//

#import "TVLoginViewController.h"

@interface TVLoginViewController ()

@end

@implementation TVLoginViewController
@synthesize trvlogueLabel = _trvlogueLabel;
@synthesize loginButton = _loginButton;

- (void)handleError:(NSError *)error andType:(NSString *)type {
    
    if (type) {
        
        [TVErrorHandler handleError:[NSError errorWithDomain:[NSString stringWithFormat:@"Could not %@", type] code:200 userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"Could not %@", type]}]];
    }
    else {
        
        [TVErrorHandler handleError:error];
    }
}

#pragma mark Login

- (void)loginIncorrectCredentials:(NSString *)callCode {
    
    __weak MBAlertView *alert = [MBAlertView alertWithBody:@"Forgot Your Pass?" cancelTitle:nil cancelBlock:nil];
    
    [alert addButtonWithText:@"No" type:MBAlertViewItemTypeDefault block:^{
        
        [alert dismiss];
    }];
    
    [alert addButtonWithText:@"Yes" type:MBAlertViewItemTypePositive block:^{
        
        // Report
        [alert dismiss];
        
        [self forgotPass];
    }];
    
    alert.size = CGSizeMake(280, 135);
    
    [alert addToDisplayQueue];
    
    [self handleError:[NSError errorWithDomain:@"Incorrect email or password" code:200 userInfo:@{NSLocalizedDescriptionKey:@"Incorrect email or password"}] andType:nil];
}

- (void)loginCorrectCredentials {

    [TVDatabase getAccountFromUser:[PFUser currentUser] isPerformingCacheRefresh:NO withCompletionHandler:^(TVAccount *account, NSMutableArray *downloadedTypes) {
        
        [TVDatabase updateMyCache:account];
    }];
    
    [((TVAppDelegate *)[UIApplication sharedApplication].delegate) didLogIn];

    [TVLoadingSignifier hideLoadingSignifier];
}

#pragma mark Others

- (void)touchedView {
    
    for (UIView *view in self.view.subviews){
        
        if ([view isKindOfClass:[UITextField class]] && [view isFirstResponder]) {
            
            [view resignFirstResponder];
        }
    }
}

- (void)commenceLoadingSignifiers {
    
    [TVLoadingSignifier signifyLoading:@"Logging you in" duration:-1];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    [textField resignFirstResponder];
    
    if (textField == emailTextField) {
        
        [passwordTextField becomeFirstResponder];
    }
    else {
        
        if ([[[passwordTextField text] stringByReplacingOccurrencesOfString:@" " withString:@""] length] && [[[emailTextField text] stringByReplacingOccurrencesOfString:@" " withString:@""] length]) {
            
            [self loginAccount];
        }
    }
    
    return YES;
}

#pragma mark UI Handling

- (void)UIBuffer {
    
    [loginButton setShowsTouchWhenHighlighted:YES];
    
    [emailTextField setBorderStyle:UITextBorderStyleNone];
    [emailTextField setNeedsDisplay];
    
    [passwordTextField setBorderStyle:UITextBorderStyleNone];
    [passwordTextField setNeedsDisplay];
        
    [[self loginButton] setImage:[UIImage imageNamed:@"button-pressed@2x.png"] forState:UIControlStateHighlighted];
    
    [[self trvlogueLabel] setFont:[UIFont fontWithName:@"Futura-Bold" size:30.0]];
    [[self trvlogueLabel] setTextColor:[UIColor darkTextColor]];
    
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(touchedView)];
    [self.view addGestureRecognizer:gestureRecognizer];
}

#pragma mark Funky, Dirty, Native :P

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self) {
    }
    
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:YES];
}

- (void)viewDidLoad
{
    [self UIBuffer];
    
    [super viewDidLoad];
    
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    
    [self setTrvlogueLabel:nil];
    [self setLoginButton:nil];
    [self setLoginLabel:nil];
    [self setRegisterAccountBtn:nil];
    
    [super viewDidUnload];
}

#pragma mark Account Registration and Logging In

- (IBAction)registerAccount {
 
    TVCreateAccountViewController *registerAccountVC = [[TVCreateAccountViewController alloc] init];
    [self.navigationController pushViewController:registerAccountVC animated:YES];
}

- (IBAction)loginAccount {

    [self commenceLoadingSignifiers];
    
    [self loginToAccount];
}

- (void)loginToAccount {
    
    [TVDatabase loginToAccountWithEmail:[[emailTextField text] stringByReplacingOccurrencesOfString:@" " withString:@""] andPassword:[passwordTextField text] withCompletionHandler:^(BOOL success, BOOL correctCredentials, NSError *error, NSString *callCode) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (!error && success) {
                
                if (correctCredentials) {

                    [self loginCorrectCredentials];
                }
                else {
                    
                    [self loginIncorrectCredentials:callCode];
                }
            }
            else {
                
                [self handleError:error andType:callCode];
            }
        });
    }];
}

- (IBAction)linkedIn {
}

#pragma mark Forgot Password

- (void)forgotPass {
    
    if ([[emailTextField.text stringByReplacingOccurrencesOfString:@" " withString:@""] length] && [self validateEmailWithString:[emailTextField.text stringByReplacingOccurrencesOfString:@" " withString:@""]]) {
        
        [TVLoadingSignifier signifyLoading:@"Requesting for a new password" duration:-1];
        
        [TVDatabase requestForNewPassword:emailTextField.text withCompletionHandler:^(BOOL succeeded, NSError *error, NSString *callCode) {
            
            if (!error && succeeded) {
                
                [TVNotificationSignifier signifyNotification:@"Check your email for more info" forDuration:4];
            }
            else {
                
                [self handleError:error andType:REQUEST_FORGOT_PASSWORD];
            }
        }];
    }
    else {
        
        [self handleError:[NSError errorWithDomain:@"Invalid email" code:200 userInfo:@{NSLocalizedDescriptionKey: @"Please enter a valid email"}] andType:nil];
    }
}

- (BOOL)validateEmailWithString:(NSString *)email
{
    NSString *emailRegEx =
    @"(?:[a-z0-9!#$%\\&'*+/=?\\^_`{|}~-]+(?:\\.[a-z0-9!#$%\\&'*+/=?\\^_`{|}"
    @"~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\"
    @"x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[a-z0-9](?:[a-"
    @"z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\\[(?:(?:25[0-5"
    @"]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-"
    @"9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21"
    @"-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])";
    
    NSPredicate *regExPredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegEx];
    
    return [regExPredicate evaluateWithObject:email];
}

@end