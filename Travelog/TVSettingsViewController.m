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

- (void)handleError:(NSError *)error andType:(NSString *)type {
    
    [TVErrorHandler handleError:[NSError errorWithDomain:[NSString stringWithFormat:@"Could not %@", type] code:200 userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"Could not %@", type]}]];
}

#pragma mark UITextField Methods

- (void)touchedView {

    for (UIView *view in self.scrollView.subviews){

        if ([view isKindOfClass:[UITextField class]] && [view isFirstResponder]) {
            
            [view resignFirstResponder];
            
            [self.scrollView setContentOffset:CGPointMake(0, -60) animated:YES];
        }
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    [self dismissKeyboard:textField];
    
    return YES;
}

- (void)dismissKeyboard:(UITextField *)tf {
    
    [tf resignFirstResponder];
    
    if (tf.tag != 4) {
        
        NSInteger i = tf.tag;
        
        UITextField *nextTf = (UITextField *)[self.view viewWithTag:i + 1];
        
        [nextTf becomeFirstResponder];
        
        [self.scrollView setContentOffset:CGPointMake(0, nextTf.center.y - 120) animated:YES];
    }
    else {
        
        [self.scrollView setContentOffset:CGPointMake(0, -60) animated:YES];
    }
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
    
    [self saveData];
}

- (void)openPhotoLibrary {
    
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    [picker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    [picker setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
    [picker setAllowsEditing:YES];
    [picker setDelegate:self];
    
    [self presentViewController:picker animated:YES completion:nil];
}

#pragma mark Validation

- (NSMutableArray *)missingFields {
    
    return [self checkIfValuesAreFilled];
}

- (NSArray *)incorrectFields {
    
    NSMutableArray *retVal = [[NSMutableArray alloc] init];
    
    [retVal addObjectsFromArray:[self missingFields]];
    
    if (retVal.count) {
        
        for (NSInteger i = 0; i <= retVal.count - 1; i++) {
            
            if ([[retVal objectAtIndex:i] intValue] == 0) {
                
                [retVal removeObjectAtIndex:i];
            }
        }
    }
    
    return retVal;
}

- (NSMutableArray *)checkIfValuesAreFilled {
    
    NSMutableArray *arrayOfValuesNotFilled = [[NSMutableArray alloc] init];
    
    for (NSInteger i = 1; i <= 4; i++) {
        
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

#pragma mark Handling Data

- (IBAction)saveData {
    
    if (![self incorrectFields].count) {
        
        [self updateAccount];
    }
    
    for (NSInteger i = 1; i <= 4; i++) {
        
        if ([[self incorrectFields] containsObject:@(i)]) {
            
            [[self.view viewWithTag:i+200] setBackgroundColor:[UIColor colorWithRed:1 green:1 blue:204.0f/255.0f alpha:1.0f]];
        }
        else {
            
            [[self.view viewWithTag:i+200] setBackgroundColor:[UIColor whiteColor]];
        }
    }
}

- (void)updateAccount {
    
    [TVLoadingSignifier signifyLoading:@"Updating your account" duration:-1];
    
    TVAccount *account = [TVDatabase currentAccount];
    
    [[account person] setPosition:jobTextField.text];
    [[account person] setName:[NSString stringWithFormat:@"%@ %@", firstNameTextField.text, lastNameTextField.text]];
    
    if ([[originCityTextField text] isEqualToString:account.person.originCity]) {
        
        [TVDatabase updateMyAccount:account immediatelyCache:YES withCompletionHandler:^(BOOL succeeded, NSError *error, NSString *callCode) {
            
            [TVLoadingSignifier hideLoadingSignifier];
            
            [self loadInData];
        }];
        
        [TVDatabase updateProfilePicture:[profileImageView.image makeThumbnailOfSize:CGSizeMake(700, 700)] withObjectId:account.userId withCompletionHandler:^(BOOL succeeded, NSError *error, NSString *callCode) {
            
            [self loadInData];
        }];
    }
    else {
        
        [self geocode:[originCityTextField text] withCompletionHandler:^(NSDictionary *result, NSError *error) {
            
            if (result && !error) {
                
                [[account person] setOriginCity:result[@"city"]];
                
                [TVDatabase updateMyAccount:account immediatelyCache:YES withCompletionHandler:^(BOOL succeeded, NSError *error, NSString *callCode) {
                    
                    [self loadInData];

                    [TVLoadingSignifier hideLoadingSignifier];
                }];
                
                [TVDatabase updateProfilePicture:[profileImageView.image makeThumbnailOfSize:CGSizeMake(700, 700)] withObjectId:account.userId withCompletionHandler:^(BOOL succeeded, NSError *error, NSString *callCode) {
                    
                    [self loadInData];
                }];
            }
            else {
                
                [TVErrorHandler handleError:[NSError errorWithDomain:@"Please input a valid city" code:200 userInfo:@{NSLocalizedDescriptionKey:@"Please input a valid city"}]];
            }
        }];
    }
    
    [self loadInData];
}

- (void)geocode:(NSString *)location withCompletionHandler:(void (^)(NSDictionary *result, NSError *error))callback {
    
    TVGoogleGeocoder *geocoder = [[TVGoogleGeocoder alloc] init];
    
    [geocoder geocodeCityWithName:location withCompletionHandler:^(NSError *error, BOOL success, NSDictionary *result) {
        
        if (!error && success) {
            
            callback(result, error);
        }
        else {
            
            callback(nil, error);
        }
    }];
}

- (void)loadInData {

    if ([[TVDatabase currentAccount] isUsingLinkedIn]) {
        
        self.linkedInStatus.text = @"Disconnect LinkedIn";
    } 
    else {
        
        self.linkedInStatus.text = @"Connect LinkedIn";
    }
    
    firstNameTextField.text = [[[[TVDatabase currentAccount] person] name] componentsSeparatedByString:@" "][0];
    lastNameTextField.text = [[[[[TVDatabase currentAccount] person] name] componentsSeparatedByString:@" "] lastObject];
    
    originCityTextField.text = [[[TVDatabase currentAccount] person] originCity];
    jobTextField.text = [[[TVDatabase currentAccount] person] position];
        
    profileImageView.image = [TVDatabase locateProfilePictureOnDiskWithUserId:[[TVDatabase currentAccount] userId]];
}

- (IBAction)logout {
    
    [TVDatabase logout];
    
    [((TVAppDelegate *)[UIApplication sharedApplication].delegate) didLogOut];
}

- (IBAction)connectWithLinkedIn {
    
    if (![[TVDatabase currentAccount] isUsingLinkedIn]) {
        
        [LinkedInAuthorizer getAuthorizationToken:^(BOOL succeeded, BOOL cancelled, NSError *error, NSString *authorizationToken) {
            
            if (!error && succeeded) {
                
                [TVLoadingSignifier signifyLoading:@"Downloading account data" duration:-1];
                
                [LinkedInAuthorizer requestAccessTokenFromAuthorizationCode:authorizationToken withCompletionHandler:^(BOOL succeeded, NSError *error, NSString *accessToken) {
                    
                    if (succeeded && !error) {
                        
                        [LinkedInDataRetriever downloadProfileWithAccessToken:accessToken andCompletionHandler:^(NSDictionary *profile, BOOL success, NSError *error) {
                            
                            if (!error && succeeded && profile.count) {
                                
                                TVAccount *newAccount = [TVDatabase currentAccount];
                                
                                [newAccount setIsUsingLinkedIn:YES];
                                [newAccount setLinkedInAccessKey:authorizationToken];
                                [newAccount setLinkedInId:profile[@"id"]];
                                
                                [TVDatabase setLocalLinkedInRequestToken:accessToken];
                                
                                [TVLoadingSignifier signifyLoading:@"Connecting LinkedIn account" duration:-1];
                                
                                [TVDatabase updateMyAccount:newAccount immediatelyCache:YES withCompletionHandler:^(BOOL succeeded, NSError *error, NSString *callCode) {
                                    
                                    if (!succeeded) {
                                        
                                        [self handleError:error andType:GET_LINKEDIN];
                                    }
                                    else {
                                        
                                        [TVNotificationSignifier signifyNotification:@"Successfully connected LinkedIn account" forDuration:4];
                                        
                                        self.linkedInStatus.text = @"Disconnect LinkedIn";
                                    }
                                }];
                            }
                            else {
                                
                                // [self handleError:error andType:GET_LINKEDIN];
                            }
                        }];
                    }
                }];
            }
        }];
    }
    else {
        
        TVAccount *newAccount = [TVDatabase currentAccount];
        
        [newAccount setIsUsingLinkedIn:NO];
        [newAccount setLinkedInAccessKey:nil];
        [newAccount setLinkedInId:nil];
        
        [TVDatabase setLocalLinkedInRequestToken:nil];

        [TVLoadingSignifier signifyLoading:@"Disconnecting LinkedIn account" duration:-1];
        
        [TVDatabase updateMyAccount:newAccount immediatelyCache:YES withCompletionHandler:^(BOOL succeeded, NSError *error, NSString *callCode) {
            
            if (!succeeded) {
                
                [self handleError:error andType:GET_LINKEDIN];
            }
            else {
                
                [TVNotificationSignifier signifyNotification:@"Successfully disconnected LinkedIn account" forDuration:4];
                
                self.linkedInStatus.text = @"Connect LinkedIn";
            }
        }];
    }
}

- (IBAction)exportFlights {

    [TVLoadingSignifier signifyLoading:@"Exporting flights" duration:-1];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, NULL), ^{
        
        NSMutableString *csv = [NSMutableString stringWithString:@"Origin,Destination,Date,Miles"];
        
        if ([[[TVDatabase currentAccount] person] flights].count) {
            
            NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
            [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
            [formatter setMaximumFractionDigits:2];
            
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"dd-MM-yyyy"];

            for (NSInteger i = 0; i <= [[[[TVDatabase currentAccount] person] flights] count] - 1; i++ ) {
                
                TVFlight *flight = [[[TVDatabase currentAccount] person] flights][i];
                
                [csv appendFormat:@"\r%@,%@,%@,%@", flight.originCity, flight.destinationCity, [dateFormatter stringFromDate:flight.date], [formatter stringFromNumber:@(flight.miles)]];
            }
        }
    
        NSString *fileName = [NSString stringWithFormat:@"%@_Flights", [[[TVDatabase currentAccount] person] name]];
        
        NSArray *arrayPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
        NSString *docDir = [arrayPaths objectAtIndex:0];
        NSString *path = [docDir stringByAppendingString:[NSString stringWithFormat:@"/%@", fileName]];
        
        [csv writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:NULL];
        NSData *csvData = [NSData dataWithContentsOfFile:path];
        
        [TVLoadingSignifier signifyLoading:@"Sending flights" duration:-1];
        
        [TVDatabase sendEmail:[@{@"subject": @"Your Exported Flights", @"data": @"As per request, your exported flights in CSV format are attached below.", @"toAddress": [[[TVDatabase currentAccount] person] email]} mutableCopy] withAttachementData:@{@"fileType": @"text/csv", @"filename": @"flights.csv", @"data": csvData} withCompletionHandler:^(BOOL success, NSError *error, NSString *callCode) {
            
            if (!error && success) {
                
                [TVNotificationSignifier signifyNotification:[NSString stringWithFormat:@"Sent to %@", [[[TVDatabase currentAccount] person] email]] forDuration:3];
            }
            else {
                
                [TVErrorHandler handleError:[NSError errorWithDomain:callCode code:200 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Could not %@", callCode]}]];
            }
        }];
    });
}

- (IBAction)support {
    
    [[Helpshift sharedInstance] showConversation:self withOptions:nil];
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    
    [controller dismissViewControllerAnimated:YES completion:nil];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id)init {
    
    if (self = [super init]) {
        
        self.tabBarItem.title = @"Settings";
        self.tabBarItem.image = [UIImage imageNamed:@"settings.png"];
        
        dispatch_async(dispatch_get_main_queue(), ^{

            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadInData) name:NSNotificationWroteMyProfilePicture object:nil];
        });
    }
    
    return self;
}

- (void)refreshGeneralDetails:(UIRefreshControl *)refreshControl {
    
    [refreshControl beginRefreshing];
    
    [[PFUser currentUser] refreshInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        
        [refreshControl endRefreshing];
        
        if (!error) {
            
            TVAccount *account = [TVDatabase getGeneralFromUser:(PFUser *)object];
            [TVDatabase updateMyCache:account];
            
            [self loadInData];
        }
    }];
}

- (void)viewDidLoad {
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refreshGeneralDetails:) forControlEvents:UIControlEventValueChanged];
    [self.scrollView addSubview:refreshControl];
    
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(touchedView)];
    [self.view addGestureRecognizer:gestureRecognizer];
    
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectWithLinkedIn) name:NSNotificationAutomateConnectWithLinkedIn object:nil];
    
    firstNameTextField.delegate = self;
    lastNameTextField.delegate = self;
    originCityTextField.delegate = self;
    jobTextField.delegate = self;
    
    [self loadInData];
    
    UIBarButtonItem *save = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveData)];
    self.navigationItem.rightBarButtonItem = save;
    
    CGRect screenRect = [[UIScreen mainScreen] applicationFrame];

    if (screenRect.size.height == 548) {

        self.scrollView.scrollEnabled = NO;
    }
    else {

        self.scrollView.center = CGPointMake(self.scrollView.center.x, self.view.frame.size.height - 195);
        self.scrollView.contentSize = CGSizeMake(320, self.view.frame.size.height + 30);
    }
    
    [self.navigationController setNavigationBarHidden:NO];
    [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStyleDone target:self action:@selector(saveData)]];
    
    self.navigationItem.title = @"Settings";

    for (UIView *view in self.scrollView.subviews) {
        
        if ([view isKindOfClass:[UIImageView class]] && view.tag != 200) {
            
            view.layer.masksToBounds = YES;
            view.clipsToBounds = YES;
            view.layer.cornerRadius = 7.0f;
        }
        else if ([view isKindOfClass:[UITextField class]]) {
            
            view.layer.cornerRadius = 7.0f;
            
            if (view.tag == 3 || view.tag == 4) {
                
                ((UITextField *)view).autocorrectionType = UITextAutocorrectionTypeYes;
            }
        }
        else if ([view isKindOfClass:[UITextView class]]) {
            
            view.layer.cornerRadius = 7.0f;
            view.layer.masksToBounds = YES;
            view.layer.borderColor = [[UIColor lightGrayColor] CGColor];
            view.layer.borderWidth = 0.5f;
        }
        else if ([view isKindOfClass:[UIButton class]]) {
            
            view.layer.cornerRadius = 7.0f;
            
            view.layer.borderColor = [[UIColor lightGrayColor] CGColor];
            view.layer.borderWidth = 0.5f;
        }
    }
    
    firstNameTextField.autocapitalizationType = UITextAutocapitalizationTypeWords;
    lastNameTextField.autocapitalizationType = UITextAutocapitalizationTypeWords;
    originCityTextField.autocapitalizationType = UITextAutocapitalizationTypeWords;
    jobTextField.autocapitalizationType = UITextAutocapitalizationTypeWords;
    
    firstNameTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    lastNameTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    originCityTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    jobTextField.autocorrectionType = UITextAutocorrectionTypeNo;

    [super viewWillAppear:animated];

    // Do any additional setup after loading the view from its nib.
}

- (IBAction)touchedDown:(id)sender {
    
    [(UIButton *)sender setAlpha:0.5f];
}

- (IBAction)released:(id)sender {
    
    [(UIButton *)sender setAlpha:1.0f];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end