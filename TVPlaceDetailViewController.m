//
//  TVPlaceDetailViewController.m
//  Trvlogue
//
//  Created by Rohan Kapur on 15/8/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import "TVPlaceDetailViewController.h"

@interface TVPlaceDetailViewController ()

@end

@implementation TVPlaceDetailViewController
@synthesize place;

#pragma mark Initialization

- (id)init {
    
    if (self = [super init]) {
        
    }
    
    return self;
}

- (id)initWithPlace:(TVGooglePlace *)_place {
    
    if (self = [self init]) {
        
        self.place = _place;
    }
    
    return self;
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
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
