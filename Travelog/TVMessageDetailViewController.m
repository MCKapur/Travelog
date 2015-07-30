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

#pragma mark Messages View Delegate

- (void)didSendText:(NSString *)text {
    
    BOOL isConnection = NO;
    
    for (TVConnection *connection in [[[TVDatabase currentAccount] person] connections]) {
        
        if ([connection.senderId isEqualToString:[[TVDatabase currentAccount] userId] ? [TVDatabase messageHistoryFromID:self.messageHistoryID].receiverId : [TVDatabase messageHistoryFromID:self.messageHistoryID].senderId] || [connection.receiverId isEqualToString:[[TVDatabase currentAccount] userId] ? [TVDatabase messageHistoryFromID:self.messageHistoryID].receiverId : [TVDatabase messageHistoryFromID:self.messageHistoryID].senderId]) {
            
            isConnection = YES;
        }
    }

    if (isConnection) {
        
        TVMessage *message = [[TVMessage alloc] initWithBody:text publishDate:[NSDate date] senderId:[[TVDatabase currentAccount] userId] andReceiverId:[[TVDatabase messageHistoryFromID:self.messageHistoryID].receiverId isEqualToString:[[TVDatabase currentAccount] userId]] ? [TVDatabase messageHistoryFromID:self.messageHistoryID].senderId : [TVDatabase messageHistoryFromID:self.messageHistoryID].receiverId];
        
        [TVDatabase sendMessage:message toHistoryWithID:self.messageHistoryID withCompletionHandler:^(BOOL success, NSError *error, NSString *callCode) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [[NSNotificationCenter defaultCenter] postNotificationName:NSNotificationSentMessage object:nil userInfo:nil];
            });
        }];
        
        [self finishSend];
        [self scrollToBottomAnimated:YES];
        [self reload];
        
        [JSMessageSoundEffect playMessageSentSound];
    }
    else {
        
        MBFlatAlertView *alertView = [MBFlatAlertView alertWithTitle:@"Error - Cannot Message" detailText:@"You can't message this person, as you are no longer connections with them" cancelTitle:@"Dismiss" cancelBlock:nil];
        [alertView show];
    }
}

- (JSBubbleMessageType)messageTypeForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return [((TVMessage *)[TVDatabase messageHistoryFromID:self.messageHistoryID].sortedMessages[indexPath.row]).senderId isEqualToString:[[TVDatabase currentAccount] userId]] ? JSBubbleMessageTypeOutgoing : JSBubbleMessageTypeIncoming;
}

- (UIImageView *)bubbleImageViewWithType:(JSBubbleMessageType)type
                       forRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [((TVMessage *)[TVDatabase messageHistoryFromID:self.messageHistoryID].sortedMessages[indexPath.row]).senderId isEqualToString:[[TVDatabase currentAccount] userId]] ? [JSBubbleImageViewFactory bubbleImageViewForType:type color:[UIColor js_bubbleBlueColor]] : [JSBubbleImageViewFactory bubbleImageViewForType:type color:[UIColor js_bubbleLightGrayColor]];
}

- (JSMessagesViewTimestampPolicy)timestampPolicy
{
    return JSMessagesViewTimestampPolicyCustom;
}

- (JSMessagesViewAvatarPolicy)avatarPolicy
{
    return JSMessagesViewAvatarPolicyAll;
}

- (JSMessagesViewSubtitlePolicy)subtitlePolicy
{
    return JSMessagesViewSubtitlePolicyAll;
}

- (JSMessageInputViewStyle)inputViewStyle
{
    return JSMessageInputViewStyleFlat;
}

#pragma mark Messages View Data Source

- (BOOL)hasTimestampForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSInteger timePeriod = 0;
    
    if (indexPath.row <= 0) {
        
        timePeriod = 18000;
    }
    else {
        
        timePeriod = [((TVMessage *)[TVDatabase messageHistoryFromID:self.messageHistoryID].sortedMessages[indexPath.row]).publishDate timeIntervalSinceDate:((TVMessage *)[TVDatabase messageHistoryFromID:self.messageHistoryID].sortedMessages[indexPath.row - 1]).publishDate];
    }
    
    return timePeriod >= 18000 ? YES : NO;
}

- (BOOL)shouldPreventScrollToBottomWhileUserScrolling
{
    return NO;
}

- (void)configureCell:(JSBubbleMessageCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    if([cell messageType] == JSBubbleMessageTypeOutgoing) {
        
        cell.bubbleView.textView.textColor = [UIColor whiteColor];
        
        if([cell.bubbleView.textView respondsToSelector:@selector(linkTextAttributes)]) {
            
            NSMutableDictionary *attrs = [cell.bubbleView.textView.linkTextAttributes mutableCopy];
            [attrs setValue:[UIColor blueColor] forKey:NSForegroundColorAttributeName];
            
            cell.bubbleView.textView.linkTextAttributes = attrs;
        }
    }
    
    if (cell.timestampLabel) {
        
        cell.timestampLabel.textColor = [UIColor lightGrayColor];
        cell.timestampLabel.shadowOffset = CGSizeZero;
    }
    
    if (cell.subtitleLabel) {
        
        cell.subtitleLabel.textColor = [UIColor lightGrayColor];
    }
}

- (NSString *)subtitleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [TVDatabase cachedAccountWithId:((TVMessage *)[TVDatabase messageHistoryFromID:self.messageHistoryID].sortedMessages[indexPath.row]).senderId].person.name;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [TVDatabase messageHistoryFromID:self.messageHistoryID].sortedMessages.count;
}

- (NSString *)textForRowAtIndexPath:(NSIndexPath *)indexPath {

    return ((TVMessage *)[TVDatabase messageHistoryFromID:self.messageHistoryID].sortedMessages[indexPath.row]).body;
}

- (NSDate *)timestampForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return ((TVMessage *)[TVDatabase messageHistoryFromID:self.messageHistoryID].sortedMessages[indexPath.row]).publishDate;
}

- (UIImageView *)avatarImageViewForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIImage *retVal = nil;
    
    if ([[[TVDatabase currentAccount] userId] isEqualToString:((TVMessage *)[TVDatabase messageHistoryFromID:self.messageHistoryID].sortedMessages[indexPath.row]).senderId]) {
        
        retVal = myProfilePic;
    }
    else {
        
        retVal = hisProfilePic;
    }

    UIImageView *imageView = [[UIImageView alloc] initWithImage:retVal];
    imageView.layer.cornerRadius = 27.0f;
    imageView.layer.masksToBounds = YES;
    
    [imageView setFrame:CGRectMake(imageView.frame.origin.x, imageView.frame.origin.y, 30, 30)];

    return imageView;
}

- (void)incomingMessage
{
    [self reload];
    [self scrollToBottomAnimated:YES];
    
    [JSMessageSoundEffect playMessageReceivedAlert];
}

#pragma mark Initialization

- (id)init {
    
    if (self = [super init]) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(incomingMessage) name:NSNotificationNewMessageIncoming object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reload) name:NSNotificationDownloadedMessages object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reload) name:NSNotificationWroteProfilePicture object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reload) name:NSNotificationSentMessage object:nil];
        });
    }
    
    return self;
}

- (id)initWithMessageHistoryID:(NSString *)_messageHistoryID {
    
    if (self = [self init]) {
        
        self.messageHistoryID = _messageHistoryID;
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

- (void)reload {
    
    [self.tableView reloadData];
    [self.tableView setNeedsDisplay];
}

- (void)viewWillAppear:(BOOL)animated {
    
    self.tabBarController.tabBar.hidden = YES;

    NSMutableArray *messages = [[NSMutableArray alloc] init];
    
    if ([[TVDatabase messageHistoryFromID:self.messageHistoryID] messages].count) {
        
        for (NSInteger i = [[TVDatabase messageHistoryFromID:self.messageHistoryID] messages].count; i--;) {
            
            TVMessage *message = [[TVDatabase messageHistoryFromID:self.messageHistoryID] messages][i];
            
            if ([message.receiverId isEqualToString:[[TVDatabase currentAccount] userId]]) {
                
                if (!message.receiverRead) {
                    
                    [messages addObject:message];
                }
            }
            else {
                
                break;
            }
        }
        
        if (messages.count) {
            
            [TVDatabase confirmReceiverHasReadMessagesinMessageHistory:[TVDatabase messageHistoryFromID:self.messageHistoryID] withCompletionHandler:^(BOOL success, NSError *error, NSString *callCode) {
                
            }];
        }
    }
    
    NSString *userId = [[[TVDatabase currentAccount] userId] isEqualToString:[TVDatabase messageHistoryFromID:self.messageHistoryID].senderId] ? [TVDatabase messageHistoryFromID:self.messageHistoryID].receiverId : [TVDatabase messageHistoryFromID:self.messageHistoryID].senderId;
    
    myProfilePic = [TVDatabase locateProfilePictureOnDiskWithUserId:[[TVDatabase currentAccount] userId]];
    hisProfilePic = [TVDatabase locateProfilePictureOnDiskWithUserId:userId];
    
    [self setBackgroundColor:[UIColor colorWithRed:64.0f/255.0f green:66.0f/255.0f blue:65.0f/255.0f alpha:1.0f]];
    
    [[JSBubbleView appearance] setFont:[UIFont systemFontOfSize:16.0f]];
    
    self.messageInputView.textView.placeHolder = @"New Message";
    
    self.navigationItem.title = [[TVDatabase messageHistoryFromID:self.messageHistoryID].receiverId isEqualToString:[[TVDatabase currentAccount] userId]] ? [TVDatabase cachedAccountWithId:[TVDatabase messageHistoryFromID:self.messageHistoryID].senderId].person.name : [TVDatabase cachedAccountWithId:[TVDatabase messageHistoryFromID:self.messageHistoryID].receiverId].person.name;

    BOOL isConnection = NO;
    
    for (TVConnection *connection in [[[TVDatabase currentAccount] person] connections]) {
        
        if ([connection.senderId isEqualToString:[[TVDatabase currentAccount] userId] ? [TVDatabase messageHistoryFromID:self.messageHistoryID].receiverId : [TVDatabase messageHistoryFromID:self.messageHistoryID].senderId] || [connection.receiverId isEqualToString:[[TVDatabase currentAccount] userId] ? [TVDatabase messageHistoryFromID:self.messageHistoryID].receiverId : [TVDatabase messageHistoryFromID:self.messageHistoryID].senderId]) {
            
            isConnection = YES;
        }
    }
    
    if (!isConnection) self.navigationItem.title = @"No Longer Connection";

    BOOL hasConnection = NO;
    
    for (TVConnection *connection in [[[TVDatabase currentAccount] person] connections]) {

        if ([connection.senderId isEqualToString:userId] || [connection.receiverId isEqualToString:userId]) {
            
            hasConnection = YES;
        }
    }
    
    [super viewWillAppear:animated];
}

- (void)viewDidLoad
{
    [self setDelegate:self];
    [self setDataSource:self];
    
    [super viewDidLoad];
}

- (void)viewWillDisappear:(BOOL)animated {
    
    self.tabBarController.tabBar.hidden = NO;
//    self.navigationController.navigationBarHidden = NO;
    
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end