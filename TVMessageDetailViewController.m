//
//  TVMessageDetailViewController.m
//  Trvlogue
//
//  Created by Rohan Kapur on 18/8/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import "TVMessageDetailViewController.h"

@interface TVMessageDetailViewController ()

@end

@implementation TVMessageDetailViewController
@synthesize messageHistoryID;

#pragma mark Table View Data Source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
   
    return [TVDatabase messageHistoryFromID:self.messageHistoryID].messages.count;
}

#pragma mark Messages View Delegate

- (void)sendPressed:(UIButton *)sender withText:(NSString *)text
{
    TVMessage *message = [[TVMessage alloc] initWithBody:text publishDate:[NSDate date] andSenderId:[[PFUser currentUser] objectId]];

    [TVDatabase sendMessage:message toHistoryWithID:self.messageHistoryID withCompletionHandler:^(BOOL success, NSError *error, NSString *callCode) {
    }];
    
    [self finishSend];
}

- (JSBubbleMessageType)messageTypeForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [((TVMessage *)[TVDatabase messageHistoryFromID:self.messageHistoryID].messages[indexPath.row]).senderId isEqualToString:[[PFUser currentUser] objectId]] ? JSBubbleMessageTypeOutgoing : JSBubbleMessageTypeIncoming;
}

- (JSBubbleMessageStyle)messageStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return JSBubbleMessageStyleSquare;
}

- (JSMessagesViewTimestampPolicy)timestampPolicy
{
    return JSMessagesViewTimestampPolicyEveryThree;
}

- (JSMessagesViewAvatarPolicy)avatarPolicy
{
    return JSMessagesViewAvatarPolicyBoth;
}

- (JSAvatarStyle)avatarStyle
{
    return JSAvatarStyleCircle;
}

//  Optional delegate method
//  Required if using `JSMessagesViewTimestampPolicyCustom`
//
//  - (BOOL)hasTimestampForRowAtIndexPath:(NSIndexPath *)indexPath
//

#pragma mark Messages View Data Source

- (NSString *)textForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return ((TVMessage *)[TVDatabase messageHistoryFromID:self.messageHistoryID].messages[indexPath.row]).body;
}

- (NSDate *)timestampForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return ((TVMessage *)[TVDatabase messageHistoryFromID:self.messageHistoryID].messages[indexPath.row]).publishDate;
}

- (UIImage *)avatarImageForIncomingMessage
{
    UIImage *profilePicture = [UIImage imageWithContentsOfFile:[NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"Documents/ProfilePicture_%@.png", ![[TVDatabase messageHistoryFromID:self.messageHistoryID].senderId isEqualToString:[[PFUser currentUser] objectId]] ? [TVDatabase messageHistoryFromID:self.messageHistoryID].senderId : [TVDatabase messageHistoryFromID:self.messageHistoryID].receiverId]]];
    
    if (!profilePicture) {
        
        profilePicture = [UIImage imageNamed:@"anonymous_person.png"];
    }
                               
    return profilePicture; 
}

- (UIImage *)avatarImageForOutgoingMessage
{
    return [[[TVDatabase currentAccount] person] getProfilePic];
}

- (void)incomingMessage
{
    [self.tableView reloadData];
    [self.tableView setNeedsDisplay];
    [self scrollToBottomAnimated:YES];
}

#pragma mark Initialization

- (UIButton *)sendButton
{
    // Override to use a custom send button
    // The button's frame is set automatically for you
    return [UIButton defaultSendButton];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)reload {
    
    [self.tableView reloadData];
    [self.tableView setNeedsDisplay];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.delegate = self;
    self.dataSource = self;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(incomingMessage) name:@"IncomingMessage" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reload) name:@"ProfilePictureDownloaded" object:nil];
}

- (void)viewDidDisappear:(BOOL)animated {
    
    [super viewDidDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"IncomingMessage" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"ProfilePictureDrawn" object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
