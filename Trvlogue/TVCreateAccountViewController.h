//
//  CreateAccountViewController.h
//  Trvlogue
//
//  Created by Rohan Kapur on 23/12/12.
//  Copyright (c) 2012 UWCSEA. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <CoreLocation/CoreLocation.h>

#import "GIFBackground.h"
#import "TVTextFileLoader.h"

#import <AddressBook/AddressBook.h>
#import <CoreLocation/CoreLocation.h>

#import "TVFlightsViewController.h"

#import "MBAlertView.h"

#import <QuartzCore/QuartzCore.h>

@interface UIImage (Thumbnail)

- (UIImage *)makeThumbnailOfSize:(CGSize)size;

@end

@implementation UIImage (Thumbnail)

- (UIImage *)makeThumbnailOfSize:(CGSize)size {
    
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);

    [self drawInRect:CGRectMake(0, 0, size.width, size.height)];
    
    UIImage *newThumbnail = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return newThumbnail;
}

@end

@interface TVCreateAccountViewController : UIViewController <UITextFieldDelegate, UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
{
    __weak IBOutlet UITextField *firstNameTextField;
    __weak IBOutlet UITextField *lastNameTextField;
    __weak IBOutlet UITextField *originCityTextField;
    __weak IBOutlet UITextField *jobTextField;
    __weak IBOutlet UITextField *emailTextField;
    __weak IBOutlet UITextField *passwordTextField;
    __weak IBOutlet UITextField *confirmPasswordTextField;
    
    TVAccount *account;
    NSMutableArray *followingArray;
        
    __weak IBOutlet UIImageView *profileImageView;
}

- (IBAction)openCameraOptions;

- (NSArray *)incorrectFields;

@property (nonatomic, strong) NSMutableDictionary *accountDict;

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@end
