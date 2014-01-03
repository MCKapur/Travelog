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
        
        int i = tf.tag;
        
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
        
        for (int i = 0; i <= retVal.count - 1; i++) {
            
            if ([[retVal objectAtIndex:i] intValue] == 0) {
                
                [retVal removeObjectAtIndex:i];
            }
        }
    }
    
    return retVal;
}

- (NSMutableArray *)checkIfValuesAreFilled {
    
    NSMutableArray *arrayOfValuesNotFilled = [[NSMutableArray alloc] init];
    
    for (int i = 1; i <= 4; i++) {
        
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
    
    if ([profileImageView.image isEqual:[TVDatabase locateProfilePictureOnDiskWithUserId:[[TVDatabase currentAccount] userId]]] && [firstNameTextField.text isEqualToString:[[[[TVDatabase currentAccount] person] name] componentsSeparatedByString:@" "][0]] && [lastNameTextField.text isEqualToString:[[[[[TVDatabase currentAccount] person] name] componentsSeparatedByString:@" "] lastObject]] && [originCityTextField.text isEqualToString:[[[TVDatabase currentAccount] person] originCity]] && [jobTextField.text isEqualToString:[[[TVDatabase currentAccount] person] position]]) {
    }
    else {
        
        if (![self incorrectFields].count) {
            
            [self updateAccount];
        }
        
        for (int i = 1; i <= 4; i++) {
            
            if ([[self incorrectFields] containsObject:@(i)]) {
                
                [[self.view viewWithTag:i+200] setBackgroundColor:[UIColor colorWithRed:1 green:1 blue:204.0f/255.0f alpha:1.0f]];
            }
            else {
                
                [[self.view viewWithTag:i+200] setBackgroundColor:[UIColor whiteColor]];
            }
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
        }];
        
        [TVDatabase updateProfilePicture:[profileImageView.image makeThumbnailOfSize:CGSizeMake(700, 700)] withObjectId:account.userId withCompletionHandler:^(BOOL succeeded, NSError *error, NSString *callCode) {
        }];
    }
    else {
        
        [self geocode:[originCityTextField text] withCompletionHandler:^(NSDictionary *result, NSError *error) {
            
            if (result && !error) {
                
                [[account person] setOriginCity:result[@"city"]];
                
                [TVDatabase updateMyAccount:account immediatelyCache:YES withCompletionHandler:^(BOOL succeeded, NSError *error, NSString *callCode) {
                    
                    [TVLoadingSignifier hideLoadingSignifier];
                }];
                
                [TVDatabase updateProfilePicture:[profileImageView.image makeThumbnailOfSize:CGSizeMake(700, 700)] withObjectId:account.userId withCompletionHandler:^(BOOL succeeded, NSError *error, NSString *callCode) {
                }];
            }
            else {
                
                [TVErrorHandler handleError:[NSError errorWithDomain:@"Please input a valid city" code:200 userInfo:@{NSLocalizedDescriptionKey:@"Please input a valid city"}]];
            }
        }];
    }
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

- (IBAction)connectWithLinkedIn:(UIButton *)sender {
    
    if (![[TVDatabase currentAccount] isUsingLinkedIn]) {
        
        [LinkedInAuthorizer authorizeWithCompletionHandler:^(BOOL succeeded, BOOL cancelled, NSError *error, NSString *accessToken) {
            NSLog(@"Callback");
            if (!error && succeeded) {
                
                [TVLoadingSignifier signifyLoading:@"Downloading account data" duration:-1];
                
                [LinkedInDataRetriever downloadProfileWithAccessToken:accessToken andCompletionHandler:^(NSDictionary *profile, BOOL success, NSError *error) {
                    
                    if (!error && succeeded && profile.count) {
                        
                        TVAccount *newAccount = [TVDatabase currentAccount];
                        
                        [newAccount setIsUsingLinkedIn:YES];
                        [newAccount setLinkedInAccessKey:accessToken];
                        [newAccount setLinkedInId:profile[@"id"]];
                        
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

//                        [self handleError:error andType:GET_LINKEDIN];
                    }
                }];
            }
            else {
                NSLog(@"Really be Really?");
                [self handleError:error andType:GET_LINKEDIN];
            }
        }];
    }
    else {
        
        TVAccount *newAccount = [TVDatabase currentAccount];
        
        [newAccount setIsUsingLinkedIn:NO];
        [newAccount setLinkedInAccessKey:nil];
        [newAccount setLinkedInId:nil];
        
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
    
    NSMutableString *csv = [NSMutableString stringWithString:@"Name,Date,Miles"];
    
    for (int i = 0; i <= [[[[TVDatabase currentAccount] person] flights] count] - 1; i++ ) {
        
        TVFlight *flight = [[[TVDatabase currentAccount] person] flights][i];
        
        [csv appendFormat:@"\n\"%@\",%@,\"%g\"", flight.originCity, flight.destinationCity, flight.miles];
    }
    
    NSString *fileName = [NSString stringWithFormat:@"%@_Flights", [[[TVDatabase currentAccount] person] name]];
    
    NSArray *arrayPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
    NSString *docDir = [arrayPaths objectAtIndex:0];
    NSString *path = [docDir stringByAppendingString:[NSString stringWithFormat:@"/%@", fileName]];
    
    [csv writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:NULL];
    NSData *csvData = [NSData dataWithContentsOfFile:path];
    
    if ([MFMailComposeViewController canSendMail]) {
        
        if ([[[TVDatabase currentAccount] person] flights].count) {
            
            MFMailComposeViewController *composeViewController = [[MFMailComposeViewController alloc] init];
            [composeViewController setSubject:@"My Flights"];
            [composeViewController addAttachmentData:csvData mimeType:@"text/csv" fileName:fileName];
            
            composeViewController.mailComposeDelegate = self;
            
            [self presentViewController:composeViewController animated:YES completion:nil];
        }

    }
    else {
            
        [TVErrorHandler handleError:[NSError errorWithDomain:@"Ensure you have added a mail account in Settings" code:200 userInfo:@{NSLocalizedDescriptionKey: @"Ensure you have added a mail account in Settings"}]];
    }
}

- (IBAction)support {
    
    MFMailComposeViewController *mailComposeViewController = [[MFMailComposeViewController alloc] init];
    [mailComposeViewController setMailComposeDelegate:self];
    
    [mailComposeViewController setSubject:[NSString stringWithFormat:@"Travelog Support from %@ - v%@", [[[TVDatabase currentAccount] person] email], [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]]];
    [mailComposeViewController setToRecipients:[NSArray arrayWithObject:@"support@travelogapp.com"]];
    [mailComposeViewController setMessageBody:@"Hi, what do you need help with?:" isHTML:NO];
    
    if ([MFMailComposeViewController canSendMail]) {
        
        [self presentViewController:mailComposeViewController animated:YES completion:nil];
    }
    else {
        
        [TVErrorHandler handleError:[NSError errorWithDomain:@"Ensure you have added a mail account in Settings" code:200 userInfo:@{NSLocalizedDescriptionKey: @"Ensure you have added a mail account in Settings"}]];
    }
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

        self.scrollView.contentSize = CGSizeMake(320, self.view.frame.size.height + 110);
    }
    
    self.scrollView.center = CGPointMake(self.scrollView.center.x, self.view.frame.size.height - 274);
    
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
        }
        else if ([view isKindOfClass:[UITextView class]]) {
            
            view.layer.cornerRadius = 7.0f;
        }
        else if ([view isKindOfClass:[UIButton class]]) {
            
            view.layer.cornerRadius = 7.0f;
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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end