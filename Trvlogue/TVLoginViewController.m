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

- (void)handleError:(NSError *)error andType:(NSString *)type {
    
    if (type) {
        
        [TVErrorHandler handleError:[NSError errorWithDomain:[NSString stringWithFormat:@"Could not %@", type] code:200 userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"Could not %@", type]}]];
    }
    else {
        
        [TVErrorHandler handleError:error];
    }
}

#pragma mark Login

- (void)loginWithAccount {
    
    TVViewController *viewController = [[TVViewController alloc] init];
    [self.navigationController pushViewController:viewController animated:YES];
}

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
        
    [self loginWithAccount];
    
    [TVLoadingSignifier hideLoadingSignifier];
}

#pragma mark Others

- (void)commenceLoadingSignifiers {
    
    [TVLoadingSignifier signifyLoading:@"Logging you in" duration:-1];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    [textField resignFirstResponder];
    
    if (textField == emailTextField) {
        
        [passwordTextField becomeFirstResponder];
    }
    
    return YES;
}

#pragma mark UI Handling

- (void)UIBuffer {
    
    [emailTextField setBorderStyle:UITextBorderStyleNone];
    [emailTextField setNeedsDisplay];
    
    [passwordTextField setBorderStyle:UITextBorderStyleNone];
    [passwordTextField setNeedsDisplay];
    
    for (UITextView *textView in self.view.subviews) {
        
        if ([textView isKindOfClass:[UITextView class]]) {
            
            [textView.layer setCornerRadius:7.0f];
            [textView.layer setMasksToBounds:YES];
        }
    }
    
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:TRVLOGUE_NAVIGATION_BAR] forBarMetrics:UIBarMetricsDefault];
    
    [[self loginButton] setImage:[UIImage imageNamed:@"button-pressed@2x.png"] forState:UIControlStateHighlighted];
    
    [[self trvlogueLabel] setFont:[UIFont fontWithName:@"Futura-Bold" size:47.0]];
    [[self trvlogueLabel] setTextColor:[UIColor whiteColor]];
    
    [gifImage animateGIF];
}

#pragma mark Funky, Dirty, Native :P

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self) {
        
        int random = arc4random() % NUMBER_OF_GIFS;
        random++;
        
        [((TVAppDelegate *)[UIApplication sharedApplication].delegate) setRandomNumber:random];
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
    
    [TVDatabase isCreatingAnAccount:NO];
    
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
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Email", @"LinkedIn", nil];
    
    [actionSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Email"]) {
        
        if ([self validateEmailWithString:[emailTextField.text stringByReplacingOccurrencesOfString:@" " withString:@""]]) {
            
            TVCreateAccountViewController *registerAccountVC = [[TVCreateAccountViewController alloc] initWithEmail:[emailTextField.text stringByReplacingOccurrencesOfString:@" " withString:@""] andPassword:passwordTextField.text];
            [self.navigationController pushViewController:registerAccountVC animated:YES];
        }
        else {
            
            [self handleError:[NSError errorWithDomain:@"Invalid email" code:200 userInfo:@{NSLocalizedDescriptionKey: @"Please enter a valid email"}] andType:nil];
        }
    }
    else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"LinkedIn"]) {
        
        [TVLoadingSignifier signifyLoading:@"Getting LinkedIn Info" duration:-1];
        
        [LinkedInAuthorizer authorizeWithCompletionHandler:^(BOOL succeeded, BOOL cancelled, NSError *error, NSString *accessToken) {
            
            if (!error && succeeded) {
                
                [LinkedInDataRetriever downloadProfileWithAccessToken:accessToken andCompletionHandler:^(NSDictionary *profile, BOOL success, NSError *error) {

                    if (!error && succeeded && profile.count) {
                        
                        [TVLoadingSignifier hideLoadingSignifier];
                        
                        TVCreateAccountViewController *registerAccountVC = [[TVCreateAccountViewController alloc] initWithPresetData:profile withAccessToken:accessToken andLinkedInId:profile[@"id"]];
                        [self.navigationController pushViewController:registerAccountVC animated:YES];
                    }
                    else {
                        
                        if (!cancelled && [error code] != 102) {
                            
                            [TVLoadingSignifier hideLoadingSignifier];
                            
                            [self handleError:error andType:Y_GET_LINKEDIN];
                        }
                    }
                }];
            }
            else {
                
                if (!cancelled && [error code] != 102) {
                    
                    [TVLoadingSignifier hideLoadingSignifier];
                    
                    [self handleError:error andType:Y_GET_LINKEDIN];
                }
            }
        }];
    }
}

- (IBAction)loginAccount {

    [self commenceLoadingSignifiers];
    
    [self loginToAccount];
}

- (void)loginToAccount {
    
    [TVDatabase loginToAccountWithEmail:[[emailTextField text] stringByReplacingOccurrencesOfString:@" " withString:@""] andPassword:[passwordTextField text] withCompletionHandler:^(BOOL success, BOOL correctCredentials, NSError *error, NSString *callCode) {
        
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
    }];
}

- (IBAction)linkedIn {
}

#pragma mark Forgot Password

- (void)forgotPass {
    
    if ([[emailTextField.text stringByReplacingOccurrencesOfString:@" " withString:@""] length] && [self validateEmailWithString:[emailTextField.text stringByReplacingOccurrencesOfString:@" " withString:@""]]) {
        
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