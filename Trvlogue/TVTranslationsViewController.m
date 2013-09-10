//
//  TVTranslationsViewController.m
//  Trvlogue
//
//  Created by Rohan Kapur on 16/8/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import "TVTranslationsViewController.h"

@interface TVTranslationsViewController ()

@end

@implementation TVTranslationsViewController
@synthesize translations;

- (id)initWithTranslations:(NSMutableArray *)_translations {
    
    if (self = [self init]) {
        
        self.translations = _translations;
    }
    
    return self;
}

- (id)init {
    
    if (self = [super init]) {
        
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
    self.navigationItem.title = @"Translations";
    
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
