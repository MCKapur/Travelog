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
    
    static NSString *CELL_ID = @"CELL_ID";
    
    TVMessageHistory *messageHistory = [[[TVDatabase currentAccount] person] messageHistories][indexPath.row];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CELL_ID];
    
    if (!cell) {
        
        UIImage *image = [TVDatabase locateProfilePictureOnDiskWithUserId:[messageHistory.senderId isEqualToString:[[PFUser currentUser] objectId]] ? messageHistory.receiverId : messageHistory.senderId];
        
        cell.imageView.image = image;
    }
    
    return cell;
}

- (void)reload {
    
    [self.messageListTableView reloadData];
    [self.messageListTableView setNeedsDisplay];
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reload) name:@"RefreshedAccount" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reload) name:@"IncomingMessage" object:nil];
    
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
