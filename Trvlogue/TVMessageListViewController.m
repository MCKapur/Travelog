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
    
    return [[[[TVDatabase currentAccount] person] sortedMessageHistories] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CELL_ID = @"CELL_ID";
    
    TVMessageHistory *messageHistory = [[[TVDatabase currentAccount] person] sortedMessageHistories][indexPath.row];
    
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
    
    cell.backgroundView = nil;
    cell.backgroundColor = [UIColor clearColor];
    
    cell.imageView.layer.cornerRadius = 22.0f;
    cell.imageView.clipsToBounds = YES;
    cell.imageView.layer.masksToBounds = YES;
    
    [[cell textLabel] setBackgroundColor:[UIColor clearColor]];
    [[cell detailTextLabel] setBackgroundColor:[UIColor clearColor]];

    if (![[[TVDatabase currentAccount] userId] isEqualToString:[[messageHistory.sortedMessages lastObject] senderId]] && [[messageHistory.sortedMessages lastObject] receiverRead] == NO) {
        
        UIView *myBackgroundView = [[UIView alloc] initWithFrame:CGRectZero];
        myBackgroundView.backgroundColor =  [UIColor colorWithRed:197.0f/255.0f green:209.0f/255.0f blue:255.0f/255.0f alpha:1.0f];
        cell.backgroundView = myBackgroundView;
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleGray;
    
    cell.textLabel.text = [[[TVDatabase cachedPersonWithId:[messageHistory.senderId isEqualToString:[[TVDatabase currentAccount] userId]] ? messageHistory.receiverId : messageHistory.senderId] person] name];

    cell.detailTextLabel.text = [[((TVMessage *)messageHistory.sortedMessages[messageHistory.sortedMessages.count - 1]) body] substringToIndex:[[((TVMessage *)messageHistory.sortedMessages[messageHistory.sortedMessages.count - 1]) body] length] >= 50 ? 50 : [[((TVMessage *)messageHistory.sortedMessages[messageHistory.sortedMessages.count - 1]) body] length]];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    TVMessageHistory *messageHistory = [[[TVDatabase currentAccount] person] sortedMessageHistories][indexPath.row];
    
    TVMessageDetailViewController *messageDetailViewController = [[TVMessageDetailViewController alloc] initWithMessageHistoryID:messageHistory.ID];
    
    [self.navigationController pushViewController:messageDetailViewController animated:YES];
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

- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
}

- (id)init {
    
    if (self = [super init]) {
        
        self.tabBarItem.title = @"Messages";
        self.navigationItem.title = @"Messages";
        self.tabBarItem.image = [UIImage imageNamed:@"messages.png"];
    }
    
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    
    [self reload];
    
    [super viewWillAppear:animated];
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
