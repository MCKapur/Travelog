//
//  TrvlogueSettingsViewController.m
//  Trvlogue
//
//  Created by Rohan Kapur on 1/4/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import "TVSettingsViewController.h"

#import "TVLoginViewController.h"

#import "TVDatabase.h"

@interface TVSettingsViewController ()

@end

@implementation TVSettingsViewController

#pragma mark Followers

- (IBAction)followers {
    
    TVFindPeopleViewController *findPeopleViewController = [[TVFindPeopleViewController alloc] init];
    
    [self.navigationController pushViewController:findPeopleViewController animated:YES];
}

#pragma mark Deleting

- (IBAction)deleteAccount {
    
    __weak MBAlertView *alert = [MBAlertView alertWithBody:@"Are you sure?\n\nYour followers will miss you! Make sure to export your flights before you leave! Deactivation will take up to 24 hours" cancelTitle:nil cancelBlock:nil];
    
    [alert addButtonWithText:@"No!" type:MBAlertViewItemTypePositive block:^{
        
        [alert dismiss];
    }];
    
    [alert addButtonWithText:@"Deactivate" type:MBAlertViewItemTypeDestructive block:^{
        
        // Report
        [alert dismiss];
    }];
    
    [alert addToDisplayQueue];
}

#pragma mark (SUBMARK) UIAlertView

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (buttonIndex == 1) {
        
        [TVLoadingSignifier signifyLoading:@"Sending deactivation request" duration:-1];
        
        NSMutableDictionary *emailOptions = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"Request to delete his/her account. email:%@",[[TVDatabase currentAccount] email]], @"data", @"Trvlogue Account Deletion Request", @"subject", VERIFIED_EMAIL_TEST, @"toAddress", nil];
        
        [self sendEmailOnDatabase:emailOptions];
    }
}

#pragma mark UITextField

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    [textField resignFirstResponder];
    
    return YES;
}

#pragma mark Camera Methods

- (IBAction)openCameraOptions {
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Take A Pic", @"Choose A Pic", nil];
    
    [actionSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Take A Pic"]) {
        
        [self openCamera];
    }
    else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Choose A Pic"]) {
        
        [self openPhotoLibrary];
    }
}

- (void)openCamera {
    
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    
    [picker setAllowsEditing:YES];
    [picker setSourceType:UIImagePickerControllerSourceTypeCamera];
    [picker setShowsCameraControls:YES];
    [picker setCameraCaptureMode:UIImagePickerControllerCameraCaptureModePhoto];
    [picker setCameraDevice:UIImagePickerControllerCameraDeviceFront];
    [picker setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
    
    [picker setDelegate:self];
    
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    profilePicture.image = info[@"UIImagePickerControllerEditedImage"];
    
    customOrNot = YES;
}

- (void)openPhotoLibrary {
    
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    [picker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    [picker setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
    [picker setAllowsEditing:YES];
    
    [picker setDelegate:self];
    
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)downloadedAccountsFromEmails:(NSMutableArray *)accounts {
    
    [TVLoadingSignifier hideLoadingSignifier];
    
    if (accounts.count) {
        
        //        FriendPickerViewController *friendPickerVC = [[FriendPickerViewController alloc] initWithAccount:arrayOfFriends andCurrentAccountDictionary:[DatabaseOperations currentAccount] andDelegate:self andIsCreatingAnAccount:NO];
        //
        //        [self.navigationController pushViewController:friendPickerVC animated:YES];
    }
    else {
        
        [TVErrorHandler handleError:[NSError errorWithDomain:@"No friends found" code:200 userInfo:@{NSLocalizedDescriptionKey:@"No friends found"}]];
    }
}

- (void)handleError:(NSError *)error andType:(NSString *)type {
    
    [TVErrorHandler handleError:[NSError errorWithDomain:[NSString stringWithFormat:@"Could not %@", type] code:200 userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"Could not %@", type]}]];
}

#pragma mark Logout

- (IBAction)logout {
    
    [TVDatabase logout];
    
    TVLoginViewController *lvc = [[TVLoginViewController alloc] init];
    [self.navigationController pushViewController:lvc animated:YES];
}

#pragma mark Account Data

- (void)sendEmailOnDatabase: (NSMutableDictionary *)emailOptions {
    
    [TVDatabase sendEmail:emailOptions withCompletionHandler:^(BOOL success, NSError *error, NSString *callCode) {
        
        if (success && !error) {
            
            [TVNotificationSignifier signifyNotification:@"We'll miss you, stay cool :)" forDuration:10];
            
            [TVDatabase logout];
            
            TVLoginViewController *lvc = [[TVLoginViewController alloc] init];
            
            [self.navigationController pushViewController:lvc animated:YES];
        }
        else {
            
            [self handleError:error andType:callCode];
        }
    }];
}

- (void)updateAccount {
    
    [TVLoadingSignifier signifyLoading:@"Saving your account" duration:-1];
    
    TVAccount *updatedTrvlogueAccount = [TVDatabase currentAccount];
    
    [updatedTrvlogueAccount.person writeProfilePictureLocally:profilePicture.image];//still need to reupload profilepicture ONLY if its changed
    [TVDatabase uploadProfilePicture:profilePicture.image withObjectId:[[PFUser currentUser] objectId]];
    
    [updatedTrvlogueAccount setEmail:[emailTextField.text stringByReplacingOccurrencesOfString:@" " withString:@""]];
    [updatedTrvlogueAccount.person setEmail:[emailTextField.text stringByReplacingOccurrencesOfString:@" " withString:@""]];
    [updatedTrvlogueAccount.person setName:nameTextField.text];
    [updatedTrvlogueAccount setPassword:passwordTextField.text];
    
    [self updateMyAccount:updatedTrvlogueAccount];
}

- (void)updateMyAccount: (TVAccount *)account {
    
    [TVDatabase updateMyAccount:account withCompletionHandler:^(BOOL success, NSError *error, NSString *callCode) {
        
        if (!error && success) {
            
            [TVNotificationSignifier signifyNotification:@"Changes have been made" forDuration:3];
        }
        else {
            
            [self handleError:error andType:callCode];
            
            if ([[error userInfo][@"code"] intValue] == [EMAIL_TAKEN intValue]) {
                
                __weak MBAlertView *alert = [MBAlertView alertWithBody:@"The email specified is already associated with an account" cancelTitle:nil cancelBlock:nil];
                
                [alert addButtonWithText:@"Okay" type:MBAlertViewItemTypeDefault block:^{
                    
                    [alert dismiss];
                }];
                
                [alert addButtonWithText:@"Report" type:MBAlertViewItemTypeDestructive block:^{
                    
                    // Report
                    [alert dismiss];
                }];
                
                alert.size = CGSizeMake(280, 180);
                
                [alert addToDisplayQueue];
            }
        }
    }];
}

- (void)saveData {
    
    if (![self checkForErrors]) {
        
        [self updateAccount];
    }
}

#pragma mark Form Validation

- (BOOL)hasChangedData {
    
    BOOL retVal = YES;
    
    if ([[emailTextField.text stringByReplacingOccurrencesOfString:@" " withString:@""] isEqualToString:[TVDatabase currentAccount].email] && [[nameTextField.text stringByReplacingOccurrencesOfString:@" " withString:@""] isEqualToString:[TVDatabase currentAccount].person.name] && [profilePicture.image isEqual:[[TVDatabase currentAccount].person getProfilePic]] && [passwordTextField.text isEqualToString:[[TVDatabase currentAccount] password]]) {
        
        retVal = NO;
    }
    
    return retVal;
}

- (int)missingFields {
    
    int retVal = 0;
    
    NSArray *array = [self checkIfValuesAreFilled];
    
    if (array.count) {
        
        retVal = 1;
        
        [TVErrorHandler handleError:[NSError errorWithDomain:@"Please fill in all fields" code:200 userInfo:@{NSLocalizedDescriptionKey:@"Please fill in all fields"}]];
    }
    
    return retVal;
}

- (NSMutableArray *)checkIfValuesAreFilled {
    
    NSMutableArray *arrayOfValuesNotFilled = [[NSMutableArray alloc] init];
    
    for (int i = 0; i <= 2; i++) {
        
        for (UIView *view in self.view.subviews) {
            
            if ([view isKindOfClass:[UITextField class]] && view.tag == i) {
                
                if (![((UITextField *)view).text stringByReplacingOccurrencesOfString:@" " withString:@""].length) {
                    
                    [arrayOfValuesNotFilled addObject:view];
                }
            }
        }
    }
    
    return arrayOfValuesNotFilled;
}

- (BOOL)checkForErrors {
    
    BOOL retVal = NO;
    
    int errorsMade = 0;
    
    errorsMade += [self checkEmailIsValid];
    errorsMade += [self missingFields];
    
    if (errorsMade) {
        
        retVal = YES;
    }
    
    return retVal;
}

- (int)checkEmailIsValid {
    
    int retVal = 0;
    
    if (![self validateEmailWithString:[emailTextField.text stringByReplacingOccurrencesOfString:@" " withString:@""]]) {
        
        retVal = 1;
        
        if (![self missingFields]) {
            
            [TVErrorHandler handleError:[NSError errorWithDomain:@"Email specified is invalid" code:200 userInfo:@{NSLocalizedDescriptionKey:@"Email specified is invalid"}]];
        }
    }
    else {
        
    }
    
    return retVal;
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

- (void)loadInAccountData {
    
    [nameTextField setText:[[TVDatabase currentAccount].person name]];
    [emailTextField setText:[[TVDatabase currentAccount] email]];
    [profilePicture setImage:[[TVDatabase currentAccount].person getProfilePic]];
    [passwordTextField setText:[[TVDatabase currentAccount] password]];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [TVDatabase isCreatingAnAccount:NO];
    
    [self loadInAccountData];
    
    UIBarButtonItem *tickItem;
    tickItem = [[UIBarButtonItem alloc] initWithTitle:@"✓" style:UIBarButtonItemStyleDone target:self action:@selector(saveData)];
    [tickItem setTitleTextAttributes:@{UITextAttributeFont:[UIFont boldSystemFontOfSize:22]} forState:UIControlStateNormal];
    [self.navigationItem setRightBarButtonItem:tickItem];
    
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end