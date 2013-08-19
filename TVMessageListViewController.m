//
//  TVMessageListViewController.m
//  Trvlogue
//
//  Created by Rohan Kapur on 18/8/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import "TVMessageListViewController.h"

@interface TVMessageListViewController ()

@end

@implementation TVMessageListViewController
@synthesize messageListTableView;

#pragma mark UITableView Methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return [[[[TVDatabase currentAccount] person] messageHistories] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    
}

#pragma mark Initialization

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
