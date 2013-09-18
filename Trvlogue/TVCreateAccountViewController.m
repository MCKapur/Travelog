
//  CreateAccountViewController.m
//  Trvlogue
//
//  Created by Rohan Kapur on 23/12/12.
//  Copyright (c) 2012 UWCSEA. All rights reserved.

#import "TVCreateAccountViewController.h"

#import <CoreLocation/CoreLocation.h>

@implementation TVCreateAccountViewController
@synthesize accountDict;

#pragma mark Extra Methods

- (BOOL)validateEmailWithString:(NSString *)_email
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
    
    return [regExPredicate evaluateWithObject:_email];
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
    
    profileImageView.image = info[@"UIImagePickerControllerEditedImage"];
}

- (void)openPhotoLibrary {
    
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    [picker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    [picker setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
    [picker setAllowsEditing:YES];
    [picker setDelegate:self];
    
    [self presentViewController:picker animated:YES completion:nil];
}

#pragma mark Account Handling

- (void)registerAction {
    
    if (![self incorrectFields].count) {
        
        [self createAccount];
    }
    
    for (int i = 1; i <= 7; i++) {
        
        if ([[self incorrectFields] containsObject:@(i)]) {
            
            [[self.view viewWithTag:i] setTintColor:[UIColor yellowColor]];
        }
        else {
            
            [[self.view viewWithTag:i] setTintColor:[UIColor whiteColor]];
        }
    }
}

- (void)createAccount {

    [TVLoadingSignifier signifyLoading:@"Creating your account" duration:-1];
    
    NSNumber *milesNumber = @0.0;
    
    if ([[NSUserDefaults standardUserDefaults] doubleForKey:@"Miles"]) {
        
        milesNumber = @([[NSUserDefaults standardUserDefaults] doubleForKey:@"Miles"]);
    }
    
    NSMutableArray *flightsArray = [[NSMutableArray alloc] init];
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"location"]) {
        
        NSArray *array = [[NSUserDefaults standardUserDefaults] objectForKey:@"location"];
        
        int countOfFlights = [array count];
        
        for (int i = 0; i <= countOfFlights - 1; i++) {
            
            CLGeocoder *geocoder = [[CLGeocoder alloc] init];
            
            [geocoder geocodeAddressString:[array[i] componentsSeparatedByString:@" to "][0] completionHandler:^(NSArray *placemarks, NSError *error) {
                
                if (!error) {
                    
                    CLLocationCoordinate2D originCoordinate = [[((CLPlacemark *)placemarks[0]) location] coordinate];
                    
                    if (CLLocationCoordinate2DIsValid(originCoordinate)) {
                        
                        [geocoder geocodeAddressString:[array[i] componentsSeparatedByString:@" to"][1] completionHandler:^(NSArray *placemarks, NSError *error) {
                            
                            if (!error) {
                                
                                CLLocationCoordinate2D destinationCoordinate = [[((CLPlacemark *)placemarks[0]) location] coordinate];
                                
                                if (CLLocationCoordinate2DIsValid(destinationCoordinate)) {
                                    
                                    NSString *originCity = [[array[i] componentsSeparatedByString:@" to "][0] componentsSeparatedByString:@","][0];
                                    
                                    NSString *destinationCity = [[array[0] componentsSeparatedByString:@" to "][1] componentsSeparatedByString:@","][0];
                                    
                                    NSArray *originString = [[array[0] componentsSeparatedByString:@" to "][0]componentsSeparatedByString:@","];
                                    
                                    NSString *originCountry = originString[originString.count - 1];
                                    
                                    NSArray *destinationString = [[array[0] componentsSeparatedByString:@" to "][1]componentsSeparatedByString:@","];
                                    
                                    NSString *destinationCountry = destinationString[destinationString.count - 1];
                                    
                                    [flightsArray addObject:[[TVFlight alloc] initWithParameters:[NSDictionary dictionaryWithObjects:@[originCity, destinationCity, originCountry, destinationCountry, [TVConversions convertStringToDate:[[NSUserDefaults standardUserDefaults] objectForKey:@"date"][i] withFormat:DAY_MONTH_YEAR], [[NSUserDefaults standardUserDefaults] objectForKey:@"miles"][i], @"", @(originCoordinate.latitude), @(originCoordinate.longitude), @(destinationCoordinate.latitude), @(destinationCoordinate.longitude)] forKeys:@[@"originCity", @"destinationCity", @"originCountry", @"destinationCountry", @"date", @"miles", @"question", @"originLatitude", @"originLongitude", @"destinationLatitude", @"destinationLongitude"]]]];
                                }
                            }
                        }];
                    }
                }
            }];
        }
    }
    
    [self geocode:[originCityTextField text] withCompletionHandler:^(CLPlacemark *placemark, NSError *error) {

        NSString *location = !placemark.locality ? placemark.administrativeArea : placemark.locality;
        
        if ([location length] && !error) {
                        
            self.accountDict = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[NSString stringWithFormat:@"%@ %@", firstNameTextField.text, lastNameTextField.text], @"name", emailTextField.text, @"email", followingArray, @"connections", milesNumber, @"miles", flightsArray, @"flights", [[NSMutableDictionary alloc] init], @"knownDestinationPreferences", location, @"originCity", [[NSMutableArray alloc] init], @"notifications", jobTextField.text, @"position", @(NO), @"isUsingLinkedIn", nil, @"linkedInAccessKey", nil, @"linkedInId", nil];
            
            account = [[TVAccount alloc] initWithProfile:self.accountDict];
            
            account.accessibilityValue = passwordTextField.text;
            
            [self registerAccount];
        }
        else {
            
            [TVErrorHandler handleError:[NSError errorWithDomain:@"Please input a valid city" code:200 userInfo:@{NSLocalizedDescriptionKey:@"Please input a valid city"}]];
        }
    }];
}

- (void)geocode:(NSString *)location withCompletionHandler:(void (^)(CLPlacemark *placemark, NSError *error))callback {
    
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];

    [geocoder geocodeAddressString:location completionHandler:^(NSArray *placemarks, NSError *error) {
        
        if (!error && placemarks.count) {
            
            callback(placemarks[0], error);
        }
        else {
            
            callback(nil, error);
        }
    }];
}

- (void)registerAccount {
    
    [self createdAccount];

    dispatch_queue_t downloadQueue = dispatch_queue_create("Upload account", NULL);
    dispatch_async(downloadQueue, ^{
        
        [TVDatabase uploadAccount:account withProfilePicture:[profileImageView.image makeThumbnailOfSize:CGSizeMake(700, 700)] andCompletionHandler:^(BOOL success, NSError *error, NSString *callCode) {

            if (success && !error) {
                
//                dispatch_queue_t downloadQueue = dispatch_queue_create("Send email", NULL);
//                
//                dispatch_async(downloadQueue, ^{
//                
//                    [TVDatabase sendEmail:[@{@"data":[[[TVTextFileLoader loadTextFile:@"registeredEmailText"] stringByReplacingOccurrencesOfString:@"name_here" withString:[account.person.name componentsSeparatedByString:@" "][0]] stringByReplacingOccurrencesOfString:@"email_here" withString:account.email], @"subject":@"Welcome To Trvlogue", @"toAddress":account.email} mutableCopy] withCompletionHandler:^(BOOL success, NSError *error, NSString *callCode) {
//                        
//                        if (success && !error) {
//                        }
//                        else {
//                            
//                            [self handleError:error andType:callCode];
//                        }
//                    }];
//                });
            }
            else {

                [self handleError:error andType:callCode];
                
                if ([[error userInfo][@"code"] intValue] == [EMAIL_TAKEN intValue]) {
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
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
                    });
                }
            }
            
            [TVLoadingSignifier hideLoadingSignifier];
        }];
    });
}

- (void)createdAccount {
    
    TVViewController *trvlogueViewController = [[TVViewController alloc] init];
    trvlogueViewController.shouldRefresh = NO;
    [self.navigationController pushViewController:trvlogueViewController animated:YES];
}

- (void)handleError:(NSError *)error andType:(NSString *)type {
    
    [TVErrorHandler handleError:[NSError errorWithDomain:[NSString stringWithFormat:@"Could not %@", type] code:200 userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"Could not %@", type]}]];
}

#pragma mark Checker Methods

- (NSMutableArray *)missingFields {
    
    return [self checkIfValuesAreFilled];
}

- (NSArray *)incorrectFields {
    
    NSMutableArray *retVal = [[NSMutableArray alloc] init];
    
    [retVal addObject:@([self checkEmailIsValid])];
    [retVal addObjectsFromArray:[self missingFields]];
    [retVal addObject:@([self checkIfPasswordsAreIdentical])];
    
    for (int i = 0; i <= retVal.count - 1; i++) {
        
        if ([[retVal objectAtIndex:i] intValue] == 0) {
            
            [retVal removeObjectAtIndex:i];
        }
    }
    
    return retVal;
}

- (int)checkEmailIsValid {
    
    int retVal = 0;
    
    if (![self validateEmailWithString:emailTextField.text]) {
        
        retVal = emailTextField.tag;
        
        if (![self missingFields]) {
            
            [TVErrorHandler handleError:[NSError errorWithDomain:@"Email specified is invalid" code:200 userInfo:@{NSLocalizedDescriptionKey:@"Email specified is invalid"}]];
        }
    }
    else {
        
    }
    
    return retVal;
}

- (int)checkIfPasswordsAreIdentical {
    
    int retVal = 0;
    
    if (![passwordTextField.text isEqualToString:confirmPasswordTextField.text])
        retVal = confirmPasswordTextField.tag;
    
    return retVal;
}

- (NSMutableArray *)checkIfValuesAreFilled {
    
    NSMutableArray *arrayOfValuesNotFilled = [[NSMutableArray alloc] init];
    
    for (int i = 1; i <= 7; i++) {
        
        for (UIView *view in self.scrollView.subviews) {
            
            if ([view isKindOfClass:[UITextField class]] && view.tag == i) {
                
                if (![((UITextField *)view).text stringByReplacingOccurrencesOfString:@" " withString:@""].length) {
                    
                    [arrayOfValuesNotFilled addObject:@(view.tag)];
                }
            }
        }
    }
    
    return arrayOfValuesNotFilled;
}

#pragma mark UITextField Goodies

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    [self dismissKeyboard:textField];
    
    return YES;
}

- (void)dismissKeyboard:(UITextField *)tf {
    
    [tf resignFirstResponder];
    
    if (tf.tag != 7) {
        
        int i = tf.tag;
        
        UITextField *nextTf = (UITextField *)[self.view viewWithTag:i + 1];
        
        [nextTf becomeFirstResponder];
        
        [self.scrollView scrollRectToVisible:CGRectMake(0, 380/(8-i), self.scrollView.frame.size.width, self.scrollView.frame.size.width) animated:YES];
    }
    else {
        
    }
}

#define FUNKY AND DIRTY AND NATIVE BRAHHH

- (id)init {
    
    self = [super init];
    
    if (self) {
        
    }
    
    return self;
}

- (id)initWithEmail:(NSString *)_email andPassword:(NSString *)_password {
    
    if (self = [self init]) {
        
    }
    
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        //         Custom initialization
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:YES];
}

- (void)viewDidLoad
{
    CGRect screenRect = [[UIScreen mainScreen] applicationFrame];
    
    if (screenRect.size.height == 568) {
        
        self.scrollView.contentSize = CGSizeMake(320, self.view.frame.size.height + 94);
    }
    else {
        
        self.scrollView.contentSize = CGSizeMake(320, self.view.frame.size.height + 134);
    }
    
    [self.navigationController setNavigationBarHidden:NO];
    [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStyleDone target:self action:@selector(registerAction)]];
    
    self.navigationItem.title = @"Register";
    
    followingArray = [[NSMutableArray alloc] init];
    
    for (UIView *view in self.scrollView.subviews) {
        
        if ([view isKindOfClass:[UIImageView class]] && view.tag != 200) {
            
            view.layer.masksToBounds = YES;
            view.clipsToBounds = YES;
            view.layer.cornerRadius = 7.0f;
        }
        else if ([view isKindOfClass:[UITextField class]]) {
            
            view.layer.cornerRadius = 7.0f;
        }
        else if ([view isKindOfClass:[UITextView class]]) {
            
            view.layer.cornerRadius = 7.0f;
        }
        else if ([view isKindOfClass:[UIButton class]]) {
            
            view.layer.cornerRadius = 7.0f;
        }
    }
    
    [super viewDidLoad];
    //     Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    
    [super viewDidUnload];
}

@end