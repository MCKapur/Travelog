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
        
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CELL_ID];
        
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        cell.textLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15.0f];
        
        cell.detailTextLabel.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:13.0f];
        cell.detailTextLabel.textColor = [UIColor darkGrayColor];
    }
    
    UIImage *image = [TVDatabase locateProfilePictureOnDiskWithUserId:[messageHistory.senderId isEqualToString:[[TVDatabase currentAccount] userId]] ? messageHistory.receiverId : messageHistory.senderId];
    
    if (!image) {
        
        image = [UIImage imageNamed:@"anonymous_person.png"];
    }
    
    cell.imageView.image = image;
    
    if (![[[TVDatabase currentAccount] userId] isEqualToString:[[messageHistory.sortedMessages lastObject] senderId]] && [[messageHistory.sortedMessages lastObject] receiverRead] == NO) {
        
        cell.backgroundColor = [UIColor colorWithRed:197.0f/255.0f green:219.0f/255.0f blue:250.0f/255.0f alpha:1.0f];
    }
    
    cell.textLabel.text = [[[TVDatabase cachedPersonWithId:[messageHistory.senderId isEqualToString:[[TVDatabase currentAccount] userId]] ? messageHistory.receiverId : messageHistory.senderId] person] name];
    cell.detailTextLabel.text = [[((TVMessage *)messageHistory.messages[0]) body] substringToIndex:[[((TVMessage *)messageHistory.messages[0]) body] length] >= 50 ? 50 : [[((TVMessage *)messageHistory.messages[0]) body] length]];
    
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
