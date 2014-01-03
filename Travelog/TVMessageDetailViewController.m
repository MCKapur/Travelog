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
    
    TVMessage *message = [[TVMessage alloc] initWithBody:text publishDate:[NSDate date] senderId:[[TVDatabase currentAccount] userId] andReceiverId:[[TVDatabase messageHistoryFromID:self.messageHistoryID].receiverId isEqualToString:[[TVDatabase currentAccount] userId]] ? [TVDatabase messageHistoryFromID:self.messageHistoryID].senderId : [TVDatabase messageHistoryFromID:self.messageHistoryID].receiverId];
    
    [TVDatabase sendMessage:message toHistoryWithID:self.messageHistoryID withCompletionHandler:^(BOOL success, NSError *error, NSString *callCode) {
        
        dispatch_async(dispatch_get_main_queue(), ^{

            [[NSNotificationCenter defaultCenter] postNotificationName:NSNotificationSentMessage object:nil userInfo:nil];
        });
    }];
}

- (AMBubbleCellType)cellTypeForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return [((TVMessage *)[TVDatabase messageHistoryFromID:self.messageHistoryID].sortedMessages[indexPath.row]).senderId isEqualToString:[[TVDatabase currentAccount] userId]] ? AMBubbleCellSent : AMBubbleCellReceived;
}

#pragma mark Messages View Data Source

- (NSString *)usernameForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return [TVDatabase cachedAccountWithId:((TVMessage *)[TVDatabase messageHistoryFromID:self.messageHistoryID].sortedMessages[indexPath.row]).senderId].person.name;
}

- (UIColor *)usernameColorForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UIColor *retVal = nil;
    
    if ([((TVMessage *)[TVDatabase messageHistoryFromID:self.messageHistoryID].sortedMessages[indexPath.row]).senderId isEqualToString:[[TVDatabase currentAccount] userId]]) {
        
        retVal = [UIColor blueColor];
    }
    else {
        
        retVal = [UIColor orangeColor];
    }
    
    return retVal;
}

- (NSInteger)numberOfRows {
    
    return [TVDatabase messageHistoryFromID:self.messageHistoryID].sortedMessages.count;
}

- (NSString *)textForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return ((TVMessage *)[TVDatabase messageHistoryFromID:self.messageHistoryID].sortedMessages[indexPath.row]).body;
}

- (NSDate *)timestampForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return ((TVMessage *)[TVDatabase messageHistoryFromID:self.messageHistoryID].sortedMessages[indexPath.row]).publishDate;
}

- (UIImage *)avatarForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    UIImage *retVal = nil;
    
    if ([[[TVDatabase currentAccount] userId] isEqualToString:((TVMessage *)[TVDatabase messageHistoryFromID:self.messageHistoryID].sortedMessages[indexPath.row]).senderId]) {
        
        retVal = myProfilePic;
    }
    else {
        
        retVal = hisProfilePic;
    }

    return retVal;
}

- (void)incomingMessage
{
    [self reload];
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
    
    [((TVAppDelegate *)[UIApplication sharedApplication].delegate) hideNotifications];
    
    self.tabBarController.tabBar.hidden = YES;
//    self.navigationController.navigationBarHidden = YES;

    NSMutableArray *messages = [[NSMutableArray alloc] init];
    
    if ([[TVDatabase messageHistoryFromID:self.messageHistoryID] messages].count) {
        
        for (int i = [[TVDatabase messageHistoryFromID:self.messageHistoryID] messages].count; i--;) {
            
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
    
    [super viewWillAppear:animated];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    NSString *userId = nil;
    
    for (TVMessage *message in [TVDatabase messageHistoryFromID:self.messageHistoryID].messages) {
        
        if ([message.senderId isEqualToString:[[TVDatabase currentAccount] userId]]) {
            
            userId = message.receiverId;
        }
        else {
            
            userId = message.senderId;
        }
    }
    
    myProfilePic = [TVDatabase locateProfilePictureOnDiskWithUserId:[[TVDatabase currentAccount] userId]];
    hisProfilePic = [TVDatabase locateProfilePictureOnDiskWithUserId:userId];

    [self setDelegate:self];
    [self setDataSource:self];
    
    [self setTableStyle:AMBubbleTableStyleFlat];

    self.navigationItem.title = [[TVDatabase messageHistoryFromID:self.messageHistoryID].receiverId isEqualToString:[[TVDatabase currentAccount] userId]] ? [TVDatabase cachedAccountWithId:[TVDatabase messageHistoryFromID:self.messageHistoryID].senderId].person.name : [TVDatabase cachedAccountWithId:[TVDatabase messageHistoryFromID:self.messageHistoryID].receiverId].person.name;
}

- (void)viewWillDisappear:(BOOL)animated {
    
    [((TVAppDelegate *)[UIApplication sharedApplication].delegate) showNotifications];

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